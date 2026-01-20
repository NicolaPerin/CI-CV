pipeline {
    agent any

    environment {
        CV_NAME = credentials('CV_NAME')
        CV_LOCATION = credentials('CV_LOCATION')
        CV_EMAIL = credentials('CV_EMAIL')
        CV_PHONE = credentials('CV_PHONE')
    }

    stages {
        stage('Build CV') {
            steps {
                script {
                    // Build the Podman image
                    sh 'podman build -t rendercv-builder .'
                    
                    // Render the CV
                    sh '''
                        podman run --rm \
                          -v $(pwd):/cv \
                          rendercv-builder \
                          rendercv render cv-public.yaml \
                          --cv.name "$CV_NAME" \
                          --cv.location "$CV_LOCATION" \
                          --cv.email "$CV_EMAIL" \
                          --cv.phone "$CV_PHONE"
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
