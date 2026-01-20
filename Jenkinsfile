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

                                    if [ "$VARIANT" = "with-photo" ]; then
                                        cp "$SECRET_PHOTO_PATH" ./profile_picture.jpg
                                    fi

                                    # Create the output directory on the host BEFORE running container
                                    mkdir -p "rendercv_output/${VARIANT}"

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

                                        # Use explicit paths for each output file
                                        rendercv render "$FINAL_YAML" \
                                            --pdf-path "cv/rendercv_output/${VARIANT}/Nicola_Perin_CV.pdf" \
                                            --typst-path "cv/rendercv_output/${VARIANT}/Nicola_Perin_CV.typ" \
                                            --markdown-path "cv/rendercv_output/${VARIANT}/Nicola_Perin_CV.md" \
                                            --html-path "cv/rendercv_output/${VARIANT}/Nicola_Perin_CV.html" \
                                            --png-path "cv/rendercv_output/${VARIANT}/Nicola_Perin_CV.png"

                                        rm "$TMP_YAML" "$FINAL_YAML"
                                        '

                                    # Debug: show what was created
                                    echo "=== Contents of rendercv_output/${VARIANT} ==="
                                    ls -la "rendercv_output/${VARIANT}/"

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