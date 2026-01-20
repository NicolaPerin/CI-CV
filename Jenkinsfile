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
        stage('Prepare Builder') {
            steps {
                // Build the image once here to avoid race conditions in the matrix
                sh 'podman build -t rendercv-builder .'
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
                    stage('Render CV') {
                        steps {
                            withCredentials([
                                file(credentialsId: 'CV_PHOTO', variable: 'CV_PHOTO_FILE')
                            ]) {
                                sh '''
                                  if [ "$VARIANT" = "with-photo" ]; then
                                    PHOTO_MOUNT="-v $CV_PHOTO_FILE:/cv/profile_picture.jpg:ro"
                                  else
                                    PHOTO_MOUNT=""
                                  fi

                                  podman run --rm \
                                    -v $(pwd):/cv \
                                    $PHOTO_MOUNT \
                                    -e CV_NAME -e CV_LOCATION -e CV_EMAIL \
                                    -e CV_PHONE -e CV_BIRTHDAY -e VARIANT \
                                    rendercv-builder \
                                    sh -c '
                                      set -e
                                      cp cv/base.yaml cv.yaml

                                      if [ "$VARIANT" = "with-photo" ]; then
                                        # Use a simpler yq merge syntax
                                        yq eval-all "select(fileIndex == 0) * select(fileIndex == 1)" \
                                           cv.yaml cv/overlays/photo.yaml > cv.tmp
                                        mv cv.tmp cv.yaml
                                      fi

                                      envsubst < cv.yaml > cv.final.yaml
                                      
                                      # Render and place in specific variant folder
                                      rendercv render cv.final.yaml --output-dir "rendercv_output/${VARIANT}"
                                    '
                                '''
                            }
                        }
                    }
                }
            }
        }

        stage('Archive PDFs') {
            steps {
                // This will grab everything inside the variant folders
                archiveArtifacts artifacts: 'rendercv_output/**/*.pdf, rendercv_output/**/*.png', fingerprint: true
            }
        }
    }
}