package main

import (
	"fmt"
	"strings"
)

type audioStreamDocument struct {
	DocumentID string   `json:"documentID"`
	Artists    []string `json:"artists"`
	Title      string   `json:"title"`
	FileType   string   `json:"fileType"`
	StorageID  string   `json:"storageID"`
}

func (document *audioStreamDocument) details() string {
	return fmt.Sprintf("Song title is " + document.Title + " by " + strings.Join(document.Artists, ","))
}
