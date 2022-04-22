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
	"io/ioutil"
	corev1 "k8s.io/api/core/v1"
	"k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/client-go/kubernetes"
	"k8s.io/client-go/rest"
	"log"
	"os"
)

func main() {
	println("Its Start here")
	workDir := os.Getenv("WORK_DIR")
	vpnFQDN := os.Getenv("VPN_FQDN") //todo: move export from shell script
	serverId := os.Getenv("SERVER_SLICEGATEWAY_NAME")
	clientId := os.Getenv("CLIENT_SLICEGATEWAY_NAME")
	namespace := os.Getenv("NAMESPACE")

	fmt.Println("workDir", workDir)
	fmt.Println("vpnFQDN..", vpnFQDN)
	fmt.Println("serverId..", serverId)
	dhPem := fmt.Sprintf("%s/ovpn/dh.pem", workDir)
	fmt.Println("dhFilePath", dhPem)
	taKey := fmt.Sprintf("%s/ovpn/ta.key", workDir)
	fmt.Println("taKey", taKey)
	clientOvpn := fmt.Sprintf("%s/ovpn/%s/client-openvpn-combined.conf", workDir, vpnFQDN)
	fmt.Println("clientOvpn data", clientOvpn)
	pkiIssued := fmt.Sprintf("%s/ovpn/pki/issued/%s.crt", workDir, serverId)
	pkiPrivate := fmt.Sprintf("%s/ovpn/pki/private/%s.key", workDir, serverId)
	pkiCa := fmt.Sprintf("%s/ovpn/pki/ca.crt", workDir)
	serverOvpnConf := fmt.Sprintf("%s/ovpn/%s/server-openvpn.conf", workDir, vpnFQDN)

	serverCcd := fmt.Sprintf("%s/ovpn/%s/ccd", workDir, vpnFQDN)
	serverCcdFile, err := readFile(serverCcd)
	if err != nil {
		log.Fatal(err)
	}
	fmt.Println("serverCcdFile content..", string(serverCcdFile))
	pkiIssuedFile, err := readFile(pkiIssued)
	if err != nil {
		log.Fatal(err)
	}
	fmt.Println("pkiIssuedFile content..", string(pkiIssuedFile))

	pkiPrivateFile, err := readFile(pkiPrivate)
	if err != nil {
		log.Fatal(err)
	}
	fmt.Println("pkiPrivateFile content..", string(pkiPrivateFile))
	pkiCaFile, err := readFile(pkiCa)
	if err != nil {
		log.Fatal(err)
	}
	fmt.Println("pkiCaFile content..", string(pkiCaFile))

	serverOvpnConfFile, err := readFile(serverOvpnConf)
	if err != nil {
		log.Fatal(err)
	}
	fmt.Println("serverOvpnConfFile content..", string(serverOvpnConfFile))
	dhPemFile, err := readFile(dhPem)
	if err != nil {
		log.Fatal(err)
	}
	fmt.Println("dhPem ccontent..", string(dhPemFile))
	taKeyFile, err := readFile(taKey)
	if err != nil {
		log.Fatal(err)
	}
	fmt.Println("taKeyFile ccontent..", string(taKeyFile))
	clientOvpnFile, err := readFile(clientOvpn)
	if err != nil {
		log.Fatal(err)
	}
	fmt.Println("clientOvpn ccontent..", string(clientOvpnFile))

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
	_, err = clientset.CoreV1().Secrets(namespace).Create(context.TODO(), &clientSecret, v1.CreateOptions{})
	if err != nil {
		log.Fatal(err)
	}
	_, err = clientset.CoreV1().Secrets(namespace).Create(context.TODO(), &serverSecret, v1.CreateOptions{})
	if err != nil {
		log.Fatal(err)
	}
	fmt.Println("Its End here")

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
