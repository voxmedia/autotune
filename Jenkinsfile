#!/usr/bin/env groovy

properties(defaultVars.projectProperties)

node {
  checkout scm

  stage('Test') {
    try {
      cancelBuildsOfSameJob()
      notifyBuild('STARTED', '#app-log-autotune')
      ansiColor('xterm') {
        withVoxOpsSSHKeyPath {
          sh "./bin/test_docker_build.sh"
          if (env.BRANCH_NAME == 'master') {
            pushGemnasiumUpdate()
          }
        }
      }
    } catch (e) {
      currentBuild.result = "FAILED"
      throw e
    } finally {
      notifyBuild(currentBuild.result, '#app-log-autotune')
    }
  }
}
