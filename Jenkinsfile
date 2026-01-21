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
                sh '''
                    rm -rf rendercv_output
                    rm -f profile_picture_*.jpg
                    podman build -t rendercv-builder .
                '''
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
                                    VARIANT_DIR="${LANG}-${PHOTO}"
                                    PHOTO_FILE="profile_picture_${VARIANT_DIR}.jpg"

                                    if [ "$PHOTO" = "with-photo" ]; then
                                        cp "$SECRET_PHOTO_PATH" "./${PHOTO_FILE}"
                                    fi

                                    podman run --rm \
                                        -v $(pwd):/cv:Z \
                                        -e CV_NAME -e CV_LOCATION -e CV_EMAIL \
                                        -e CV_PHONE -e CV_BIRTHDAY \
                                        -e PHOTO_FILE="${PHOTO_FILE}" \
                                        rendercv-builder \
                                        bash cv/scripts/build.sh "$LANG" "$PHOTO"

                                    if [ -f "./${PHOTO_FILE}" ]; then
                                        rm "./${PHOTO_FILE}"
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

    post {
        always {
            sh 'rm -f profile_picture_*.jpg'
            sh 'rm -rf rendercv_output || true'  // optional: clean on failure
        }
        failure {
            echo 'Build failed - check logs above'
        }
    }
}