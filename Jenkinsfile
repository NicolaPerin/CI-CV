pipeline {
    agent any

    environment {
        CV_NAME     = credentials('CV_NAME')
        CV_LOCATION = credentials('CV_LOCATION')
        CV_EMAIL    = credentials('CV_EMAIL')
        CV_PHONE    = credentials('CV_PHONE')
        CV_BIRTHDAY = credentials('CV_BIRTHDAY')
    }

    stages {
        stage('Initialize') {
            steps {
                sh 'rm -rf rendercv_output'
            }
        }

        stage('Build CV Matrix') {
            matrix {
                axes {
                    axis {
                        name 'VARIANT'
                        values 'with-photo', 'no-photo'
                    }
                }

                stages {
                    stage('Render') {
                        steps {
                            withCredentials([file(credentialsId: 'CV_PHOTO', variable: 'SECRET_PHOTO_PATH')]) {
                                sh '''
                                    podman build -t rendercv-builder .

                                    # 1. Copy photo to workspace if it exists for this variant
                                    if [ "$VARIANT" = "with-photo" ]; then
                                        cp "$SECRET_PHOTO_PATH" ./profile_picture.jpg
                                    fi

                                    # 2. Run the build
                                    podman run --rm \
                                        -v $(pwd):/cv:Z \
                                        -e CV_NAME -e CV_LOCATION -e CV_EMAIL \
                                        -e CV_PHONE -e CV_BIRTHDAY -e VARIANT \
                                        rendercv-builder \
                                        sh -c '
                                        set -e
                                        TMP_YAML="cv_${VARIANT}.yaml"
                                        FINAL_YAML="cv_${VARIANT}.final.yaml"

                                        cp cv/base.yaml "$TMP_YAML"

                                        if [ "$VARIANT" = "with-photo" ]; then
                                            yq eval-all "select(fileIndex == 0) * select(fileIndex == 1)" \
                                            "$TMP_YAML" cv/overlays/photo.yaml > "${TMP_YAML}.tmp"
                                            mv "${TMP_YAML}.tmp" "$TMP_YAML"
                                        fi

                                        envsubst < "$TMP_YAML" > "$FINAL_YAML"
                                        
                                        rendercv render "$FINAL_YAML" --output-dir "rendercv_output/${VARIANT}"
                                        
                                        # Clean up the temporary YAMLs inside the container context
                                        rm "$TMP_YAML" "$FINAL_YAML"
                                        '

                                    # 3. SAFE CLEANUP: Only delete the photo after the container is totally finished
                                    if [ -f ./profile_picture.jpg ]; then
                                        rm ./profile_picture.jpg
                                    fi
                                '''
                            }
                        }
                    }
                }
            }
        }

        stage('Archive Results') {
            steps {
                archiveArtifacts artifacts: 'rendercv_output/**/*.pdf', fingerprint: true
            }
        }
    }
}