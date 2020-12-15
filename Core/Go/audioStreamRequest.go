package main

import (
	"encoding/json"
	"io/ioutil"
	"net/http"
)

type audioStreamRequest struct {
	DocumentID string `json:"documentID"`
}

func decodeAudioStreamRequest(httpRequest *http.Request) (audioStreamRequest, error) {
	var request audioStreamRequest
	body, readErr := ioutil.ReadAll(httpRequest.Body)
	if readErr != nil {
		return request, readErr
	}
	unMarshallErr := json.Unmarshal(body, &request)
	if unMarshallErr != nil {
		return request, unMarshallErr
	}
	return request, nil
}
