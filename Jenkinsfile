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
                // Clear the output folder at the start of the whole run
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

                                  # Create branch-specific filenames to prevent race conditions
                                  TMP_YAML="cv_${VARIANT}.yaml"
                                  FINAL_YAML="cv_${VARIANT}.final.yaml"

                                  # 1. Start with a clean copy of the base
                                  cp cv/base.yaml ${TMP_YAML}

                                  # 2. Handle photo variant
                                  if [ "$VARIANT" = "with-photo" ]; then
                                    cp "$SECRET_PHOTO_PATH" ./profile_picture.jpg
                                    
                                    # Merge the photo overlay into the branch-specific YAML
                                    yq eval-all 'select(fileIndex == 0) * select(fileIndex == 1)' \
                                       ${TMP_YAML} cv/overlays/photo.yaml > ${TMP_YAML}.tmp
                                    mv ${TMP_YAML}.tmp ${TMP_YAML}
                                  fi

                                  # 3. Inject secrets into the branch-specific YAML
                                  envsubst < ${TMP_YAML} > ${FINAL_YAML}

                                  # 4. Run Podman
                                  # We mount the whole directory but tell RenderCV to use the specific FINAL_YAML
                                  podman run --rm \
                                    -v $(pwd):/cv:Z \
                                    -e VARIANT \
                                    rendercv-builder \
                                    rendercv render ${FINAL_YAML} --output-dir "rendercv_output/${VARIANT}"

                                  # 5. Cleanup branch-specific temporary files
                                  rm -f ${TMP_YAML} ${FINAL_YAML} ./profile_picture.jpg
                                '''
                            }
                        }
                    }
                }
            }
        }

        stage('Archive Results') {
            steps {
                // This will archive only the specific subfolders, avoiding top-level clutter
                archiveArtifacts artifacts: 'rendercv_output/with-photo/*.pdf, rendercv_output/no-photo/*.pdf', 
                                 fingerprint: true, 
                                 allowEmptyArchive: false
            }
        }
    }
}