pipeline {
    agent {
        node {
            label 'base'
        }
    }
    parameters {
        booleanParam defaultValue: false, description: 'Whether to upload the packages in playground repositories', name: 'PLAYGROUND'
    }
    options {
        buildDiscarder(logRotator(numToKeepStr: '20'))
        timeout(time: 1, unit: 'HOURS')
        skipDefaultCheckout()
    }
    stages {
        stage('Stash') {
            steps {
                checkout scm
                script {
                    env.GIT_COMMIT = sh(script: 'git rev-parse HEAD', returnStdout: true).trim()
                }
                stash includes: "**", name: 'project'
            }
        }
        stage('Build Ubuntu') {
            parallel {
                stage('Ubuntu 20.04') {
                    agent {
                        node {
                            label 'yap-ubuntu-20-v1'
                        }
                    }
                    steps {
                        container('yap') {
                            unstash 'project'
                            script {
                                sh 'sudo yap prepare ubuntu -g'
                                if (BRANCH_NAME == 'devel') {
                                    def timestamp = new Date().format('yyyyMMddHHmmss')
                                    sh "sudo yap build ubuntu-focal . -r ${timestamp}"
                                } else {
                                    sh 'sudo yap build ubuntu-focal .'
                                }
                            }
                            stash includes: 'artifacts/', name: 'artifacts-focal-deb'
                        }
                    }
                    post {
                        always {
                            archiveArtifacts artifacts: "artifacts/*focal*.deb", fingerprint: true
                        }
                    }
                }
                stage('Ubuntu 22.04') {
                    agent {
                        node {
                            label 'yap-ubuntu-22-v1'
                        }
                    }
                    steps {
                        container('yap') {
                            unstash 'project'
                            sh 'sudo yap prepare ubuntu -g'
                            script {
                                if (BRANCH_NAME == 'devel') {
                                    def timestamp = new Date().format('yyyyMMddHHmmss')
                                    sh "sudo yap build ubuntu-jammy . -r ${timestamp}"
                                } else {
                                    sh 'sudo yap build ubuntu-jammy .'
                                }
                            }
                            stash includes: "artifacts/*jammy*.deb", name: 'artifacts-jammy-deb'
                        }
                    }
                    post {
                        always {
                            archiveArtifacts artifacts: "artifacts/*jammy*.deb", fingerprint: true
                        }
                    }
                }
                stage('Ubuntu 24.04') {
                    agent {
                        node {
                            label 'yap-ubuntu-24-v1'
                        }
                    }
                    steps {
                        container('yap') {
                            unstash 'project'
                            sh 'sudo yap prepare ubuntu -g'                            
                            script {
                                if (BRANCH_NAME == 'devel') {
                                    def timestamp = new Date().format('yyyyMMddHHmmss')
                                    sh "sudo yap build ubuntu-noble . -r ${timestamp}"
                                } else {
                                    sh 'sudo yap build ubuntu-noble .'
                                }
                            }
                            stash includes: "artifacts/*noble*.deb", name: 'artifacts-noble-deb'
                        }
                    }
                    post {
                        always {
                            archiveArtifacts artifacts: "artifacts/*noble*.deb", fingerprint: true
                        }
                    }
                }
            }
        }
        stage('Build RHEL') {
            parallel {
                stage('RHEL 8') {
                    agent {
                        node {
                            label 'yap-rocky-8-v1'
                        }
                    }
                    steps {
                        container('yap') {
                            unstash 'project'
                            sh 'sudo yap prepare rocky -g' 
                            script {
                                if (BRANCH_NAME == 'devel') {
                                    def timestamp = new Date().format('yyyyMMddHHmmss')
                                    sh "sudo yap build rocky-8 . -r ${timestamp}"
                                } else {
                                    sh 'sudo yap build rocky-8 .'
                                }
                            }
                            stash includes: 'artifacts/*el8*.rpm', name: 'artifacts-rocky-8'
                        }
                    }
                    post {
                        always {
                            archiveArtifacts artifacts: "artifacts/*el8*.rpm", fingerprint: true
                        }
                    }
                }
                stage('RHEL 9') {
                    agent {
                        node {
                            label 'yap-rocky-9-v1'
                        }
                    }
                    steps {
                        container('yap') {
                            unstash 'project'
                            sh 'sudo yap prepare rocky -g' 
                            script {
                                if (BRANCH_NAME == 'devel') {
                                    def timestamp = new Date().format('yyyyMMddHHmmss')
                                    sh "sudo yap build rocky-9 . -r ${timestamp}"
                                } else {
                                    sh 'sudo yap build rocky-9 .'
                                }
                            }
                            stash includes: 'artifacts/*el9*.rpm', name: 'artifacts-rocky-9'
                        }
                    }
                    post {
                        always {
                            archiveArtifacts artifacts: "artifacts/*el9*.rpm", fingerprint: true
                        }
                    }
                }
            }
        }
        stage('Upload To Playground') {
            when {
                anyOf {
                    branch 'playground/*'
                    expression { params.PLAYGROUND == true }
                }
            }
            steps {
                unstash 'artifacts-focal-deb'
                unstash 'artifacts-jammy-deb'
                unstash 'artifacts-noble-deb'
                unstash 'artifacts-rocky-8'
                unstash 'artifacts-rocky-9'

                script {
                    def server = Artifactory.server 'zextras-artifactory'
                    def buildInfo
                    def uploadSpec

                    buildInfo = Artifactory.newBuildInfo()
                    uploadSpec = """{
                        "files": [
                                    {
                                        "pattern": "artifacts/*focal*.deb",
                                        "target": "ubuntu-playground/pool/",
                                        "props": "deb.distribution=focal;deb.component=main;deb.architecture=amd64;vcs.revision=${env.GIT_COMMIT}"
                                    },
                                    {
                                        "pattern": "artifacts/*jammy*.deb",
                                        "target": "ubuntu-playground/pool/",
                                        "props": "deb.distribution=jammy;deb.component=main;deb.architecture=amd64;vcs.revision=${env.GIT_COMMIT}"
                                    },
                                    {
                                        "pattern": "artifacts/*nbole*.deb",
                                        "target": "ubuntu-playground/pool/",
                                        "props": "deb.distribution=noble;deb.component=main;deb.architecture=amd64;vcs.revision=${env.GIT_COMMIT}"
                                    },
                                    {
                                        "pattern": "artifacts/(service-discover-base)-(*).el8.x86_64.rpm",
                                        "target": "centos8-playground/zextras/{1}/{1}-{2}.el8.x86_64.rpm",
                                        "props": "rpm.metadata.arch=x86_64;rpm.metadata.vendor=zextras;vcs.revision=${env.GIT_COMMIT}"
                                    },
                                    {
                                        "pattern": "artifacts/(service-discover-base)-(*).el9.x86_64.rpm",
                                        "target": "rhel9-playground/zextras/{1}/{1}-{2}.el9.x86_64.rpm",
                                        "props": "rpm.metadata.arch=x86_64;rpm.metadata.vendor=zextras;vcs.revision=${env.GIT_COMMIT}"
                                    }
                        ]
                    }"""
                    server.upload spec: uploadSpec, buildInfo: buildInfo, failNoOp: false
                }
            }
        }
        stage('Upload To Devel') {
            when {
                branch 'devel'
            }
            steps {
                unstash 'artifacts-focal-deb'
                unstash 'artifacts-jammy-deb'
                unstash 'artifacts-noble-deb'
                unstash 'artifacts-rocky-8'
                unstash 'artifacts-rocky-9'

                script {
                    def server = Artifactory.server 'zextras-artifactory'
                    def buildInfo
                    def uploadSpec

                    buildInfo = Artifactory.newBuildInfo()
                    uploadSpec = """{
                        "files": [
                                    {
                                        "pattern": "artifacts/*focal*.deb",
                                        "target": "ubuntu-devel/pool/",
                                        "props": "deb.distribution=focal;deb.component=main;deb.architecture=amd64;vcs.revision=${env.GIT_COMMIT}"
                                    },
                                    {
                                        "pattern": "artifacts/*jammy*.deb",
                                        "target": "ubuntu-devel/pool/",
                                        "props": "deb.distribution=jammy;deb.component=main;deb.architecture=amd64;vcs.revision=${env.GIT_COMMIT}"
                                    },
                                    {
                                        "pattern": "artifacts/*noble*.deb",
                                        "target": "ubuntu-devel/pool/",
                                        "props": "deb.distribution=noble;deb.component=main;deb.architecture=amd64;vcs.revision=${env.GIT_COMMIT}"
                                    },
                                    {
                                        "pattern": "artifacts/(service-discover-base)-(*).el8.x86_64.rpm",
                                        "target": "centos8-devel/zextras/{1}/{1}-{2}.el8.x86_64.rpm",
                                        "props": "rpm.metadata.arch=x86_64;rpm.metadata.vendor=zextras;vcs.revision=${env.GIT_COMMIT}"
                                    },
                                    {
                                        "pattern": "artifacts/(service-discover-base)-(*).el9.x86_64.rpm",
                                        "target": "rhel9-devel/zextras/{1}/{1}-{2}.el9.x86_64.rpm",
                                        "props": "rpm.metadata.arch=x86_64;rpm.metadata.vendor=zextras;vcs.revision=${env.GIT_COMMIT}"
                                    }
                        ]
                    }"""
                    server.upload spec: uploadSpec, buildInfo: buildInfo, failNoOp: false
                }
            }
        }
        stage('Upload & Promotion Config') {
            when {
                buildingTag()
            }
            steps {
                unstash 'artifacts-focal-deb'
                unstash 'artifacts-jammy-deb'
                unstash 'artifacts-noble-deb'
                unstash 'artifacts-rocky-8'
                unstash 'artifacts-rocky-9'

                script {
                    def server = Artifactory.server 'zextras-artifactory'
                    def buildInfo
                    def uploadSpec
                    def config

                    //ubuntu
                    buildInfo = Artifactory.newBuildInfo()
                    buildInfo.name += "-ubuntu"
                    uploadSpec= """{
                                "files": [
                                    {
                                        "pattern": "artifacts/*focal*.deb",
                                        "target": "ubuntu-rc/pool/",
                                        "props": "deb.distribution=focal;deb.component=main;deb.architecture=amd64;vcs.revision=${env.GIT_COMMIT}"
                                    },
                                    {
                                        "pattern": "artifacts/*jammy*.deb",
                                        "target": "ubuntu-rc/pool/",
                                        "props": "deb.distribution=jammy;deb.component=main;deb.architecture=amd64;vcs.revision=${env.GIT_COMMIT}"
                                    },
                                    {
                                        "pattern": "artifacts/*noble*.deb",
                                        "target": "ubuntu-rc/pool/",
                                        "props": "deb.distribution=noble;deb.component=main;deb.architecture=amd64;vcs.revision=${env.GIT_COMMIT}"
                                    }
                                ]
                            }"""
                    server.upload spec: uploadSpec, buildInfo: buildInfo, failNoOp: false
                    config = [
                            'buildName'          : buildInfo.name,
                            'buildNumber'        : buildInfo.number,
                            'sourceRepo'         : 'ubuntu-rc',
                            'targetRepo'         : 'ubuntu-release',
                            'comment'            : 'Do not change anything! just press the button',
                            'status'             : 'Released',
                            'includeDependencies': false,
                            'copy'               : true,
                            'failFast'           : true
                    ]
                    Artifactory.addInteractivePromotion server: server, promotionConfig: config, displayName: "Ubuntu Promotion to Release"
                    server.publishBuildInfo buildInfo

                    //centos8
                    buildInfo = Artifactory.newBuildInfo()
                    buildInfo.name += "-centos8"
                    uploadSpec= """{
                                "files": [
                                    {
                                        "pattern": "artifacts/(service-discover-base)-(*).el8.x86_64.rpm",
                                        "target": "centos8-rc/zextras/{1}/{1}-{2}.el8.x86_64.rpm",
                                        "props": "rpm.metadata.arch=x86_64;rpm.metadata.vendor=zextras;vcs.revision=${env.GIT_COMMIT}"
                                    }
                                ]
                            }"""
                    server.upload spec: uploadSpec, buildInfo: buildInfo, failNoOp: false
                    config = [
                            'buildName'          : buildInfo.name,
                            'buildNumber'        : buildInfo.number,
                            'sourceRepo'         : 'centos8-rc',
                            'targetRepo'         : 'centos8-release',
                            'comment'            : 'Do not change anything! just press the button',
                            'status'             : 'Released',
                            'includeDependencies': false,
                            'copy'               : true,
                            'failFast'           : true
                    ]
                    Artifactory.addInteractivePromotion server: server, promotionConfig: config, displayName: "Centos8 Promotion to Release"
                    server.publishBuildInfo buildInfo

                    //rhel9
                    buildInfo = Artifactory.newBuildInfo()
                    buildInfo.name += "-rhel9"
                    uploadSpec= """{
                                "files": [
                                    {
                                        "pattern": "artifacts/(service-discover-base)-(*).el9.x86_64.rpm",
                                        "target": "rhel9-rc/zextras/{1}/{1}-{2}.el9.x86_64.rpm",
                                        "props": "rpm.metadata.arch=x86_64;rpm.metadata.vendor=zextras;vcs.revision=${env.GIT_COMMIT}"
                                    }
                                ]
                            }"""
                    server.upload spec: uploadSpec, buildInfo: buildInfo, failNoOp: false
                    config = [
                            'buildName'          : buildInfo.name,
                            'buildNumber'        : buildInfo.number,
                            'sourceRepo'         : 'rhel9-rc',
                            'targetRepo'         : 'rhel9-release',
                            'comment'            : 'Do not change anything! just press the button',
                            'status'             : 'Released',
                            'includeDependencies': false,
                            'copy'               : true,
                            'failFast'           : true
                    ]
                    Artifactory.addInteractivePromotion server: server, promotionConfig: config, displayName: "RHEL9 Promotion to Release"
                    server.publishBuildInfo buildInfo
                }
            }
        }
    }
    post {
        always {
            script {
                GIT_COMMIT_EMAIL = sh(
                        script: 'git --no-pager show -s --format=\'%ae\'',
                        returnStdout: true
                ).trim()
            }
            emailext attachLog: true, body: '$DEFAULT_CONTENT', recipientProviders: [requestor()], subject: '$DEFAULT_SUBJECT', to: "${GIT_COMMIT_EMAIL}"
        }
    }
}
