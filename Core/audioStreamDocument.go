package main

import (
	"fmt"
	"strings"
)

type FileType string

const (
	Mp3 FileType = "mp3"
)

type audioStreamDocument struct {
	DocumentID string   `json:"documentID"`
	Artists    []string `json:"artists"`
	Title      string   `json:"title"`
	FileType   FileType `json:"fileType"`
	StorageID  string   `json:"storageID"`
}

func (document *audioStreamDocument) details() string {
	return fmt.Sprintf("Song is " + document.Title + " by " + strings.Join(document.Artists, ","))
}
