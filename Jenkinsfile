// SPDX-FileCopyrightText: 2021-2026 Zextras <https://www.zextras.com>
//
// SPDX-License-Identifier: AGPL-3.0-only

library(
    identifier: 'jenkins-lib-common@1.3.1',
    retriever: modernSCM([
        $class: 'GitSCMSource',
        credentialsId: 'jenkins-integration-with-github-account',
        remote: 'git@github.com:zextras/jenkins-lib-common.git',
    ])
)

properties(defaultPipelineProperties())

pipeline {
    agent {
        node {
            label 'base'
        }
    }

    options {
        buildDiscarder(logRotator(numToKeepStr: '20'))
        timeout(time: 1, unit: 'HOURS')
        skipDefaultCheckout()
    }

    stages {
        stage('Setup') {
            steps {
                checkout scm
                script {
                    gitMetadata()
                }
            }
        }

        stage('Build deb/rpm') {
            steps {
                echo 'Building deb/rpm packages'
                buildStage([
                    prepare: true,
                    prepareFlags: ' -g ',
                ])
            }
        }

        stage('Upload artifacts')
        {
            tools {
                jfrog 'jfrog-cli'
            }
            steps {
                uploadStage(
                    packages: yapHelper.resolvePackageNames()
                )
            }
        }
    }

    post {
        always {
            emailext([
                attachLog: true,
                body: '$DEFAULT_CONTENT',
                recipientProviders: [requestor()],
                subject: '$DEFAULT_SUBJECT',
                to: env.GIT_COMMIT_EMAIL
            ])
        }
    }
}
