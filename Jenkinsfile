pipeline {
    agent any
    
    stages {
        stage('Build CV') {
            steps {
                script {
                    // Build the Podman image
                    sh 'podman build -t rendercv-builder .'
                    
                    // Render the CV
                    sh 'podman run --rm -v /home/nicola/curriculum-ci:/cv rendercv-builder rendercv render cv.yaml'
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
