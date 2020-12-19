package main

type audioStreamResponse struct {
	Document        audioStreamDocument `json:"document"`
	AudioBufferSize int                 `json:"audioBufferSize"`
	AudioBuffer     []byte              `json:"audioBuffer"`
}
