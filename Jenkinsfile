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

                                  # Copy photo to workspace if needed (so the container can see it)
                                  if [ "$VARIANT" = "with-photo" ]; then
                                    cp "$SECRET_PHOTO_PATH" ./profile_picture.jpg
                                  fi

                                  # We run everything inside the container to ensure tool consistency
                                  podman run --rm \
                                    -v $(pwd):/cv:Z \
                                    -e CV_NAME -e CV_LOCATION -e CV_EMAIL \
                                    -e CV_PHONE -e CV_BIRTHDAY -e VARIANT \
                                    rendercv-builder \
                                    sh -c '
                                      set -e
                                      # Use variant-specific names to avoid race conditions
                                      TMP_YAML="cv_${VARIANT}.yaml"
                                      FINAL_YAML="cv_${VARIANT}.final.yaml"

                                      cp cv/base.yaml "$TMP_YAML"

                                      if [ "$VARIANT" = "with-photo" ]; then
                                        # Use the Go-yq inside the container (this will now work!)
                                        yq eval-all "select(fileIndex == 0) * select(fileIndex == 1)" \
                                           "$TMP_YAML" cv/overlays/photo.yaml > "${TMP_YAML}.tmp"
                                        mv "${TMP_YAML}.tmp" "$TMP_YAML"
                                      fi

                                      # Use envsubst inside the container
                                      envsubst < "$TMP_YAML" > "$FINAL_YAML"
                                      
                                      rendercv render "$FINAL_YAML" --output-dir "rendercv_output/${VARIANT}"
                                    '

                                  # Cleanup photo after the branch is done
                                  rm -f ./profile_picture.jpg
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