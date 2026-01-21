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
                        name 'PHOTO'
                        values 'with-photo', 'no-photo'
                    }
                    axis {
                        name 'LANG'
                        values 'en', 'it'
                    }
                }

                stages {
                    stage('Render') {
                        steps {
                            withCredentials([file(credentialsId: 'CV_PHOTO', variable: 'SECRET_PHOTO_PATH')]) {
                                sh '''
                                    podman build -t rendercv-builder .

                                    if [ "$PHOTO" = "with-photo" ]; then
                                        cp "$SECRET_PHOTO_PATH" ./profile_picture.jpg
                                    fi

                                    VARIANT_DIR="${LANG}-${PHOTO}"
                                    mkdir -p "rendercv_output/${VARIANT_DIR}"

                                    podman run --rm \
                                        -v $(pwd):/cv:Z \
                                        -e CV_NAME -e CV_LOCATION -e CV_EMAIL \
                                        -e CV_PHONE -e CV_BIRTHDAY \
                                        -e PHOTO -e LANG \
                                        rendercv-builder \
                                        sh -c '
                                        set -e
                                        VARIANT_DIR="${LANG}-${PHOTO}"
                                        TMP_YAML="cv_${VARIANT_DIR}.yaml"
                                        FINAL_YAML="cv_${VARIANT_DIR}.final.yaml"

                                        cp cv/base.yaml "$TMP_YAML"

                                        yq eval-all "select(fileIndex == 0) * select(fileIndex == 1)" \
                                            "$TMP_YAML" "cv/overlays/lang-${LANG}.yaml" > "${TMP_YAML}.tmp"
                                        mv "${TMP_YAML}.tmp" "$TMP_YAML"

                                        if [ "$PHOTO" = "with-photo" ]; then
                                            yq eval-all "select(fileIndex == 0) * select(fileIndex == 1)" \
                                                "$TMP_YAML" cv/overlays/photo.yaml > "${TMP_YAML}.tmp"
                                            mv "${TMP_YAML}.tmp" "$TMP_YAML"
                                        fi

                                        envsubst < "$TMP_YAML" > "$FINAL_YAML"

                                        rendercv render "$FINAL_YAML" \
                                            --pdf-path "rendercv_output/${VARIANT_DIR}/Nicola_Perin_CV.pdf" \
                                            --dont-generate-html \
                                            --dont-generate-markdown \
                                            --dont-generate-png

                                        rm "$TMP_YAML" "$FINAL_YAML"
                                        '

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