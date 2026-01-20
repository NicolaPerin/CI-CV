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
        stage('Build CV Matrix') {
            matrix {
                axes {
                    axis {
                        name 'VARIANT'
                        values 'with-photo', 'no-photo'
                    }
                }

                stages {
                    stage('Render CV') {
                        steps {
                            // Using withCredentials to get the path to the secret file
                            withCredentials([file(credentialsId: 'CV_PHOTO', variable: 'SECRET_PHOTO_PATH')]) {
                                sh '''
                                  # Build the image
                                  podman build -t rendercv-builder .

                                  # Preparation: If with-photo, copy secret to workspace so Podman sees it clearly
                                  if [ "$VARIANT" = "with-photo" ]; then
                                    cp "$SECRET_PHOTO_PATH" ./profile_picture.jpg
                                    # Ensure the file isn't empty
                                    if [ ! -s ./profile_picture.jpg ]; then
                                       echo "ERROR: profile_picture.jpg is empty!"
                                       exit 1
                                    fi
                                  fi

                                  podman run --rm \
                                    -v $(pwd):/cv:Z \
                                    -e CV_NAME -e CV_LOCATION -e CV_EMAIL -e CV_PHONE -e CV_BIRTHDAY -e VARIANT \
                                    rendercv-builder \
                                    sh -c '
                                      set -e
                                      cp cv/base.yaml cv.yaml

                                      if [ "$VARIANT" = "with-photo" ]; then
                                        # Use yq to merge the photo config
                                        yq eval-all "select(fileIndex == 0) * select(fileIndex == 1)" \
                                           cv.yaml cv/overlays/photo.yaml > cv.tmp
                                        mv cv.tmp cv.yaml
                                      fi

                                      # Replace env vars and render
                                      envsubst < cv.yaml > cv.final.yaml
                                      rendercv render cv.final.yaml --output-dir "rendercv_output/${VARIANT}"
                                    '

                                  # Cleanup sensitive photo from workspace after rendering
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

        stage('Archive PDFs') {
            steps {
                archiveArtifacts artifacts: 'rendercv_output/**/*.pdf', fingerprint: true
            }
        }
    }
}