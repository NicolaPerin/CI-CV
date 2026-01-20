pipeline {
    agent any

    environment {
        CV_NAME = credentials('CV_NAME')
        CV_LOCATION = credentials('CV_LOCATION')
        CV_EMAIL = credentials('CV_EMAIL')
        CV_PHONE = credentials('CV_PHONE')
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
                                    podman run --rm \
                                    -v $(pwd):/cv \
                                    -v "$CV_PHOTO_FILE:/cv/profile_picture.jpg:ro" \
                                    -e CV_NAME \
                                    -e CV_LOCATION \
                                    -e CV_EMAIL \
                                    -e CV_PHONE \
                                    -e CV_BIRTHDAY \
                                    -e VARIANT \
                                    rendercv-builder \
                                    sh -c '
                                        set -e

                                        if [ "$VARIANT" = "with-photo" ]; then
                                            export CV_PHOTO_PATH=profile_picture.jpg
                                        else
                                            export CV_PHOTO_PATH=""
                                        fi

                                        envsubst < cv-public.yaml > cv.yaml
                                        mkdir -p rendercv_output/${VARIANT}
                                        rendercv render cv.yaml --output-dir rendercv_output/${VARIANT}
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
