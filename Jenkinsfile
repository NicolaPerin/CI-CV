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
                            withCredentials([
                                file(credentialsId: 'CV_PHOTO', variable: 'CV_PHOTO_FILE')
                            ]) {
                                sh '''
                                  podman build -t rendercv-builder .

                                  if [ "$VARIANT" = "with-photo" ]; then
                                    PHOTO_MOUNT="-v $CV_PHOTO_FILE:/cv/profile_picture.jpg:ro"
                                  else
                                    PHOTO_MOUNT=""
                                  fi

                                  podman run --rm \
                                    -v $(pwd):/cv \
                                    $PHOTO_MOUNT \
                                    -e CV_NAME \
                                    -e CV_LOCATION \
                                    -e CV_EMAIL \
                                    -e CV_PHONE \
                                    -e CV_BIRTHDAY \
                                    -e VARIANT \
                                    rendercv-builder \
                                    sh -c '
                                      set -e

                                      # Start from base
                                      cp cv/base.yaml cv.yaml

                                      # Apply overlays
                                      if [ "$VARIANT" = "with-photo" ]; then
                                        yq eval-all \
                                          '"'"'select(fileIndex == 0) * select(fileIndex == 1)'"'"' \
                                          cv.yaml cv/overlays/photo.yaml > cv.tmp
                                        mv cv.tmp cv.yaml
                                      fi

                                      # Inject secrets
                                      envsubst < cv.yaml > cv.final.yaml

                                      mkdir -p rendercv_output/${VARIANT}
                                      rendercv render cv.final.yaml --output-dir rendercv_output/${VARIANT}
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
                archiveArtifacts artifacts: 'rendercv_output/**', fingerprint: true
            }
        }
    }
}
