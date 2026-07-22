// SPDX-FileCopyrightText: 2021-2026 Zextras <https://www.zextras.com>
//
// SPDX-License-Identifier: AGPL-3.0-only

library(
    identifier: 'jenkins-lib-common@v3.5.1',
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
                gitMetadata()
            }
        }

        stage('Security Scan') {
            steps { gitleaksStage() }
        }

        stage('Build deb/rpm') {
            steps {
                echo 'Building deb/rpm packages'
                buildStage([
                    prepare: true,
                    prepareFlags: ' -g ',
                ])
                buildStage([
                    architecture: 'aarch64',
                    distros: ['ubuntu-jammy'],
                    parallelBuilds: false,
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
                uploadStage()
                uploadStage(
                    architecture: 'aarch64',
                    distros: ['ubuntu-jammy'],
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
