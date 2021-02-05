pipeline {
    agent {
        node {
            label 'base-agent-v1'
        }
    }
    options {
        buildDiscarder(logRotator(numToKeepStr: '5'))
        timeout(time: 1, unit: 'HOURS')
    }

    stages {
        stage('Stash') {
            steps {
                checkout scm
                stash includes: "*", name: 'project'
            }
        }
        stage('Ubuntu 16.04') {
            agent {
                node {
                    label 'pacur-agent-ubuntu-16.04-v1'
                }
            }
            options {
                skipDefaultCheckout()
            }
            steps {
                unstash 'project'
                sh 'mkdir artifacts'
                sh 'cp PKGBUILD /pacur'
                sh 'sudo pacur-build'
                sh 'sudo cp /pacur/service-discover-base_*.deb artifacts/'
                dir("artifacts/") {
                    sh 'echo service-discover-base* | sed -E "s#(service-discover-base_[0-9.]*).*#\\0 \\1_amd64.deb#" | xargs mv'
                }
                stash includes: 'artifacts/', name: 'artifacts-deb'
            }
            post {
                always {
                    archiveArtifacts artifacts: "artifacts/*.deb", fingerprint: true
                }
            }
        }
        stage('Centos 7') {
            agent {
                node {
                    label 'pacur-agent-centos-7-v1'
                }
            }
            options {
                skipDefaultCheckout()
            }
            steps {
                unstash 'project'
                sh 'mkdir artifacts'
                sh 'cp PKGBUILD /pacur'
                sh 'sudo pacur-build'
                sh 'sudo cp /pacur/service-discover-base*.rpm artifacts/'
                dir("artifacts/") {
                    sh 'echo service-discover-base* | sed -E "s#(service-discover-base-[0-9.]*).*#\\0 \\1.x86_64.rpm#" | xargs mv'
                }
                stash includes: 'artifacts/', name: 'artifacts-rpm'
            }
            post {
                always {
                    archiveArtifacts artifacts: "artifacts/*.rpm", fingerprint: true
                }
            }
        }

        stage('Upload') {
            when {
                buildingTag()
            }
            steps {
                unstash 'artifacts-rpm'
                unstash 'artifacts-deb'
                script {
                    def server = Artifactory.server 'zextras-artifactory'
                    def buildInfo = Artifactory.newBuildInfo()
                    def uploadSpec = """{
								"files": [
								    {
										"pattern": "artifacts/service-discover-base*.deb",
										"target": "debian-local/pool/",
										"props": "deb.distribution=xenial;deb.component=main;deb.architecture=amd64"
									},
									{
										"pattern": "artifacts/service-discover-base*.deb",
										"target": "debian-local/pool/",
										"props": "deb.distribution=bionic;deb.component=main;deb.architecture=amd64"
									},
									{
										"pattern": "artifacts/service-discover-base*.deb",
										"target": "debian-local/pool/",
										"props": "deb.distribution=focal;deb.component=main;deb.architecture=amd64"
									},
									{
										"pattern": "artifacts/(service-discover-base)-(*).rpm",
										"target": "rpm-local/zextras/{1}/{1}-{2}.rpm",
										"props": "rpm.metadata.arch=x86_64;rpm.metadata.vendor=Zextras"
									}
								]
							}"""
                    server.upload spec: uploadSpec, buildInfo: buildInfo
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