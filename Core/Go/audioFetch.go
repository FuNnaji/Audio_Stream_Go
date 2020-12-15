package main

import (
	"encoding/json"
	"io/ioutil"
	"os"
)

func fetchAudioDocument(documentID string, document *audioStreamDocument) error {
	pathPrefix := "Document/"
	pathSuffix := ".json"
	fullPath := pathPrefix + documentID + pathSuffix
	file, openErr := os.Open(fullPath)
	if openErr != nil {
		return openErr
	}
	byteValue, readErr := ioutil.ReadAll(file)
	if readErr != nil {
		return readErr
	}
	unmarshalErr := json.Unmarshal(byteValue, document)
	if unmarshalErr != nil {
		return unmarshalErr
	}
	return nil
}

func fetchAudioFile(document *audioStreamDocument) ([]byte, error) {
	pathPrefix := "Storage/"
	fullPath := pathPrefix + document.StorageID + "." + document.FileType
	file, openErr := os.Open(fullPath)
	if openErr != nil {
		return nil, openErr
	}
	byteValue, readErr := ioutil.ReadAll(file)
	if readErr != nil {
		return nil, readErr
	}
	return byteValue, nil
}

func audioByte(documentID string) ([]byte, error) {
	var document audioStreamDocument
	docErr := fetchAudioDocument(documentID, &document)
	if docErr != nil {
		return nil, docErr
	}
	audioByte, fileErr := fetchAudioFile(&document)
	return audioByte, fileErr
}
