package main

import (
	//"crypto"
	//"crypto/aes"
	//"crypto/cipher"
	"crypto/rand"
	"crypto/sha256"
	"encoding/hex"
	"fmt"
	//"io"
	"os"
	"io/ioutil"
	"crypto"
	"encoding/pem"
	"crypto/x509"
	"crypto/rsa"
)

func verify(sigString string, rsaPubKey rsa.PublicKey, message []byte) {
	hashed := sha256.Sum256(message)
	signature, _ := hex.DecodeString(sigString)
	err := rsa.VerifyPKCS1v15(&rsaPubKey, crypto.SHA256, hashed[:], signature)
	if err != nil {
		fmt.Println(err)
	}
	fmt.Println("Valid signature")
}

func main() {

	pass := os.Args[1]
	privateKeyFile := os.Args[2]
	pemString, err1 := ioutil.ReadFile(privateKeyFile)

	certFile := os.Args[3]
	certPemString, err2 := ioutil.ReadFile(certFile)

	if err1 != nil && err2 != nil {
		fmt.Println(err1)
		fmt.Println(err2)
	} else {
		block, _ := pem.Decode([]byte(pemString))
		key, _ := x509.ParsePKCS1PrivateKey(block.Bytes)

		if pass == "pass" {
			password:="1234567890"
			b, _:=x509.DecryptPEMBlock(block, []byte(password))
			key, _ = x509.ParsePKCS1PrivateKey(b)
		}

		rng := rand.Reader
		message := []byte(certPemString)
		hashed := sha256.Sum256(message)
		signature, err := rsa.SignPKCS1v15(rng, key, crypto.SHA256, hashed[:])
		if err != nil {
			fmt.Print(err)
		} else {
			sigString := hex.EncodeToString(signature)
			fmt.Println(sigString)
			f, err := os.Create("sig")
			if err == nil {
				f.WriteString(sigString)
			}
			// verify(sigString, key.PublicKey, message)
		}

	}
}
