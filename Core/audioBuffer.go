package main

import (
	"encoding/json"
	"fmt"
	"io/ioutil"
	"os"
)

func fetchAudioDocument(documentID string, document *audioStreamDocument) error {
	pathPrefix := "../Document/"
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

func fetchAudioFile(document *audioStreamDocument) ([]byte, int, error) {
	pathPrefix := "../Storage/"
	fullPath := pathPrefix + document.StorageID + "." + fmt.Sprintf("%s", document.FileType)
	file, openErr := os.Open(fullPath)
	if openErr != nil {
		return nil, 0, openErr
	}
	defer file.Close()
	fileInfo, statErr := file.Stat()
	if statErr != nil {
		return nil, 0, statErr
	}
	fileSize := fileInfo.Size()
	buffer := make([]byte, fileSize)
	byteValue, readErr := file.Read(buffer)
	if readErr != nil {
		return nil, 0, readErr
	}
	return buffer, byteValue, nil
}

func createAudioBuffer(documentID string) (audioStreamResponse, error) {
	var document audioStreamDocument
	var file audioStreamResponse
	docErr := fetchAudioDocument(documentID, &document)
	if docErr != nil {
		return file, docErr
	}
	audioBuffer, audioBufferSize, fileErr := fetchAudioFile(&document)
	file = audioStreamResponse{Document: document, AudioBuffer: audioBuffer, AudioBufferSize: audioBufferSize}
	return file, fileErr
}
