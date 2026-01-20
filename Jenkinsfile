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
        stage('Build CV') {
            steps {
                script {
                    // Build the Podman image
                    sh 'podman build -t rendercv-builder .'

                    // Generate cv.yaml from template and render the CV
                    sh '''
                        podman run --rm \
                        -v $(pwd):/cv \
                        -e CV_NAME \
                        -e CV_LOCATION \
                        -e CV_EMAIL \
                        -e CV_PHONE \
                        -e CV_BIRTHDAY \
                        rendercv-builder \
                        sh -c '
                            : "${CV_NAME:?Missing CV_NAME}"
                            : "${CV_LOCATION:?Missing CV_LOCATION}"
                            : "${CV_EMAIL:?Missing CV_EMAIL}"
                            : "${CV_PHONE:?Missing CV_PHONE}"
                            : "${CV_BIRTHDAY:?Missing CV_BIRTHDAY}"

                            envsubst < cv-public.yaml > cv.yaml
                            rendercv render cv.yaml
                        '
                    '''
                }
            }
        }
        
        stage('Archive PDF') {
            steps {
                // Archive the generated PDF as an artifact
                archiveArtifacts artifacts: 'rendercv_output/*.pdf', fingerprint: true
            }
        }
    }
}
