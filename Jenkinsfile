pipeline {
    agent {
        node {
            label 'base-agent-v1'
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
                stash includes: "**", name: 'project'
            }
        }
        stage('Build') {
            parallel {
                stage('Ubuntu 18.04') {
                    agent {
                        node {
                            label 'pacur-agent-ubuntu-18.04-v1'
                        }
                    }
                    steps {
                        unstash 'project'
                        sh 'sudo pacur build ubuntu'
                        stash includes: 'artifacts/', name: 'artifacts-deb'
                    }
                    post {
                        always {
                            archiveArtifacts artifacts: "artifacts/*.deb", fingerprint: true
                        }
                    }
                }
                stage('Centos 8') {
                    agent {
                        node {
                            label 'pacur-agent-centos-8-v1'
                        }
                    }
                    steps {
                        unstash 'project'
                        sh 'sudo pacur build centos'
                        dir("artifacts/") {
                            sh 'echo service-discover-base* | sed -E "s#(service-discover-base-[0-9.]*).*#\\0 \\1.x86_64.rpm#" | xargs sudo mv'
                        }
                        stash includes: 'artifacts/', name: 'artifacts-rpm'
                    }
                    post {
                        always {
                            archiveArtifacts artifacts: "artifacts/*.rpm", fingerprint: true
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
                unstash 'artifacts-deb'
                unstash 'artifacts-rpm'
                script {
                    def server = Artifactory.server 'zextras-artifactory'
                    def buildInfo
                    def uploadSpec

                    buildInfo = Artifactory.newBuildInfo()
                    uploadSpec = """{
                        "files": [
                                    {
                                        "pattern": "artifacts/service-discover-base*.deb",
                                        "target": "ubuntu-playground/pool/",
                                        "props": "deb.distribution=xenial;deb.distribution=bionic;deb.distribution=focal;deb.component=main;deb.architecture=amd64"
                                    },
                                    {
                                        "pattern": "artifacts/(service-discover-base)-(*).rpm",
                                        "target": "centos8-playground/zextras/{1}/{1}-{2}.rpm",
                                        "props": "rpm.metadata.arch=x86_64;rpm.metadata.vendor=zextras"
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
                unstash 'artifacts-rpm'
                unstash 'artifacts-deb'
                script {
                    def server = Artifactory.server 'zextras-artifactory'
                    def buildInfo
                    def uploadSpec
                    def config

                    //since artifactory doesn't support a build with multiple repository involved
                    //we artificially create 3 different artifactory builds by changing the build
                    //name with "-ubuntu" "-centos7" "-centos8"

                    //ubuntu
                    buildInfo = Artifactory.newBuildInfo()
                    buildInfo.name += "-ubuntu"
                    uploadSpec= """{
                                "files": [
                                    {
                                        "pattern": "artifacts/service-discover-base*.deb",
                                        "target": "ubuntu-rc/pool/",
                                        "props": "deb.distribution=xenial;deb.distribution=bionic;deb.distribution=focal;deb.component=main;deb.architecture=amd64"
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
                                        "pattern": "artifacts/(service-discover-base)-(*).rpm",
                                        "target": "centos8-rc/zextras/{1}/{1}-{2}.rpm",
                                        "props": "rpm.metadata.arch=x86_64;rpm.metadata.vendor=zextras"
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
