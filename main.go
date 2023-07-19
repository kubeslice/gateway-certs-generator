/*
 * 	# Copyright (c) 2022 Avesha, Inc. All rights reserved. # # SPDX-License-Identifier: Apache-2.0
 * 	#
 * 	# Licensed under the Apache License, Version 2.0 (the "License");
 * 	# you may not use this file except in compliance with the License.
 * 	# You may obtain a copy of the License at
 * 	#
 * 	# http://www.apache.org/licenses/LICENSE-2.0
 * 	#
 * 	# Unless required by applicable law or agreed to in writing, software
 * 	# distributed under the License is distributed on an "AS IS" BASIS,
 * 	# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * 	# See the License for the specific language governing permissions and
 * 	# limitations under the License.
 */

package main

import (
	"context"
	"fmt"
	"github.com/kubeslice/gateway-certs-generator/util"
	"go.uber.org/zap"
	"go.uber.org/zap/zapcore"
	"io/ioutil"
	corev1 "k8s.io/api/core/v1"
	"k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/client-go/kubernetes"
	"k8s.io/client-go/rest"
	"log"
	"os"
)

func main() {
	logLevel := os.Getenv("LOG_LEVEL")
	// initialize logger
	zapLogLevel := util.GetZapLogLevel(logLevel)
	initLogger(zapLogLevel)
	logger := zap.S()

	logger.Info("Certificate Generation Started.")
	workDir := os.Getenv("WORK_DIR")
	vpnFQDN := os.Getenv("VPN_FQDN") //todo: move export from shell script
	serverId := os.Getenv("SERVER_SLICEGATEWAY_NAME")
	clientId := os.Getenv("CLIENT_SLICEGATEWAY_NAME")
	namespace := os.Getenv("NAMESPACE")

	logger.Debug("workDir", workDir)
	logger.Debug("vpnFQDN..", vpnFQDN)
	logger.Debug("serverId..", serverId)
	dhPem := fmt.Sprintf("%s/ovpn/dh.pem", workDir)
	logger.Debug("dhFilePath", dhPem)
	taKey := fmt.Sprintf("%s/ovpn/ta.key", workDir)
	logger.Debug("taKey", taKey)
	clientOvpn := fmt.Sprintf("%s/ovpn/%s/client-openvpn-combined.conf", workDir, vpnFQDN)
	logger.Debug("clientOvpn data", clientOvpn)
	pkiIssued := fmt.Sprintf("%s/ovpn/pki/issued/%s.crt", workDir, serverId)
	pkiPrivate := fmt.Sprintf("%s/ovpn/pki/private/%s.key", workDir, serverId)
	pkiCa := fmt.Sprintf("%s/ovpn/pki/ca.crt", workDir)
	serverOvpnConf := fmt.Sprintf("%s/ovpn/%s/server-openvpn.conf", workDir, vpnFQDN)

	serverCcd := fmt.Sprintf("%s/ovpn/%s/ccd", workDir, vpnFQDN)
	serverCcdFile, err := readFile(serverCcd)
	if err != nil {
		logger.Error(err)
		return
	}
	logger.Debug("serverCcdFile content..", string(serverCcdFile))
	logger.Info("serverCcdFile has been generated.")

	pkiIssuedFile, err := readFile(pkiIssued)
	if err != nil {
		logger.Error(err)
		return
	}
	logger.Debug("pkiIssuedFile content..", string(pkiIssuedFile))
	logger.Info("pkiIssuedFile has been generated.")

	pkiPrivateFile, err := readFile(pkiPrivate)
	if err != nil {
		logger.Error(err)
		return
	}
	logger.Debug("pkiPrivateFile content..", string(pkiPrivateFile))
	logger.Info("pkiPrivateFile has been generated.")

	pkiCaFile, err := readFile(pkiCa)
	if err != nil {
		logger.Error(err)
		return
	}
	logger.Debug("pkiCaFile content..", string(pkiCaFile))
	logger.Info("pkiCaFile has been generated.")

	serverOvpnConfFile, err := readFile(serverOvpnConf)
	if err != nil {
		logger.Error(err)
		return
	}
	logger.Debug("serverOvpnConfFile content..", string(serverOvpnConfFile))
	logger.Info("serverOvpnConfFile has been generated.")

	dhPemFile, err := readFile(dhPem)
	if err != nil {
		logger.Error(err)
		return
	}
	logger.Debug("dhPem content..", string(dhPemFile))
	logger.Info("dhPem has been generated.")

	taKeyFile, err := readFile(taKey)
	if err != nil {
		logger.Error(err)
		return
	}
	logger.Debug("taKeyFile content..", string(taKeyFile))
	logger.Info("taKeyFile has been generated.")

	clientOvpnFile, err := readFile(clientOvpn)
	if err != nil {
		logger.Error(err)
		return
	}
	logger.Debug("clientOvpn content..", string(clientOvpnFile))
	logger.Info("clientOvpn has been generated.")

	config, err := rest.InClusterConfig()
	if err != nil {
		panic(err.Error())
	}
	// creates the clientset
	clientset, err := kubernetes.NewForConfig(config)
	if err != nil {
		panic(err.Error())
	}
	clientSecret := corev1.Secret{
		ObjectMeta: v1.ObjectMeta{Name: clientId},
		Data: map[string][]byte{
			"ovpnConfigFile": clientOvpnFile,
		},
	}
	serverSecret := corev1.Secret{
		ObjectMeta: v1.ObjectMeta{Name: serverId},
		Data: map[string][]byte{
			"ovpnConfigFile":    serverOvpnConfFile,
			"pkiDhPemFile":      dhPemFile,
			"pkiTAKeyFile":      taKeyFile,
			"pkiIssuedCertFile": pkiIssuedFile,
			"pkiPrivateKeyFile": pkiPrivateFile,
			"pkiCACertFile":     pkiCaFile,
			"ccdFile":           serverCcdFile,
		}}
	// delete any existing secrets present
	_ = clientset.CoreV1().Secrets(namespace).Delete(context.TODO(), clientSecret.Name, v1.DeleteOptions{})
	_ = clientset.CoreV1().Secrets(namespace).Delete(context.TODO(), serverSecret.Name, v1.DeleteOptions{})

	_, err = clientset.CoreV1().Secrets(namespace).Create(context.TODO(), &clientSecret, v1.CreateOptions{})
	if err != nil {
		logger.Error(err)
		return
	}
	_, err = clientset.CoreV1().Secrets(namespace).Create(context.TODO(), &serverSecret, v1.CreateOptions{})
	if err != nil {
		logger.Error(err)
		return
	}
	logger.Info("Certificate Generation Completed.")

}
func readFile(path string) ([]byte, error) {
	file, err := os.Open(path)
	if err != nil {
		return nil, err
	}
	defer func() {
		if err = file.Close(); err != nil {
			log.Fatal(err)
		}
	}()

	b, err := ioutil.ReadAll(file)
	if err != nil {
		return nil, err
	}
	return b, nil
}

func initLogger(logLevel zapcore.Level) {
	config := zap.NewDevelopmentConfig()
	config.Level = zap.NewAtomicLevelAt(logLevel)
	logg, _ := config.Build()
	zap.ReplaceGlobals(logg)
}
