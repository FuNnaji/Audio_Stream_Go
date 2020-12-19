import SwiftUI
import PlaygroundSupport
PlaygroundPage.current.needsIndefiniteExecution = true

struct AudioStreamRequest: Encodable {
    let documentID: String
}

struct AudioStreamDocument: Decodable {
    enum FileType: String, Decodable {
        case mp3 = "mp3"
    }
    let documentID: String
    let artists: [String]
    let title: String
    let fileType: FileType
    let storageID: String
}

struct AudioStreamResponse: Decodable {
    let document: AudioStreamDocument
    let audioBuffer: Data
    let audioBufferSize: Int
}

struct AudioNetwork {
    static let audioStreamURL = "http://127.0.0.1:8080/"
    
    static func makeNetworkRequest(request: URLRequest, completionHandler: @escaping (Data?, Error?) -> Void) {
        let downloadTask = URLSession.shared.dataTask(with: request, completionHandler: {(data, response, error) in
            completionHandler(data, error)
        })
        downloadTask.resume()
    }
    
    static func decodeJSONDataToResponse(data: Data) -> (AudioStreamResponse?, String?) {
        do {
            return (try JSONDecoder().decode(AudioStreamResponse.self, from: data), nil)
        } catch {
            return (nil, error.localizedDescription)
        }
    }
    
    static func encodeRequestToJSONData(request: AudioStreamRequest) -> (Data?, String?) {
        do {
            return (try JSONEncoder().encode(request), nil)
        } catch {
            return (nil, error.localizedDescription)
        }
    }
}

class AudioStream: ObservableObject {
    static let shared: AudioStream = AudioStream()
    
    enum StreamState {
        case streaming
        case notStreaming
        case idle
        case error
    }
    
    @Published var streamState: StreamState = .idle
    private var requestError: String = ""
    @Published var currentSong: AudioStreamResponse?
    
    func createRequest(id: String, serverUrl: String) -> URLRequest? {
        requestError = ""
        let requestBody = AudioStreamRequest(documentID: id)
        let encodedRequestBody = AudioNetwork.encodeRequestToJSONData(request: requestBody)
        guard let url = URL(string: serverUrl), let data = encodedRequestBody.0 else {
            streamState = .error
            requestError = encodedRequestBody.1 ?? NSLocalizedString("Unable to request audio stream", comment: "")
            print("Audio Stream Internal Error => \(requestError)")
            return nil
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = data
        return request
    }
    
    func initiateRequest(id: String, serverUrl: String, completionHandler: @escaping (Data?, Error?) -> Void) {
        guard let request = createRequest(id: id, serverUrl: serverUrl) else {
            let error = NSError(domain: "", code: 500, userInfo:[NSLocalizedDescriptionKey: requestError]) as Error
            return completionHandler(nil, error)
        }
        AudioNetwork.makeNetworkRequest(request: request, completionHandler: completionHandler)
        return
    }
}

struct AudioStreamView: View {
    @State private var streamState: AudioStream.StreamState = AudioStream.shared.streamState
    @State private var audioTitle: String = NSLocalizedString("No Audio Streaming", comment: "")
    @State private var audioArtists: String = NSLocalizedString("Artists", comment: "")
    @State private var currentAudioIndex: Int = 0
    private let audioIDS: [String] = ["00", "01", "02", "03"]
    
    var body: some View {
        VStack(alignment: .center) {
            HStack(alignment: .center, spacing: 20) {
                Button(action: {}) {
                    HStack {
                        Image(systemName: "backward.end.fill")
                    }
                }
                Button(action: tooglePlay) {
                    HStack {
                        streamState == .streaming ? Image(systemName: "pause.fill"): Image(systemName: "play.fill")
                    }
                }
                Button(action: {}) {
                    HStack {
                        Image(systemName: "forward.end.fill")
                    }
                }
            }.foregroundColor(.purple)
            Spacer(minLength: 15)
            Text(LocalizedStringKey(audioTitle))
                .font(.headline)
                .foregroundColor(.black)
                .lineLimit(3)
                .minimumScaleFactor(0.35)
            Spacer(minLength: 5)
            Text(LocalizedStringKey(audioArtists))
                .font(.footnote)
                .foregroundColor(.gray)
        }.padding()
    }
    
    func tooglePlay() {
        switch streamState {
        case .streaming:
            streamState = .notStreaming // Pause Streaming
        case .notStreaming:
            streamState = .streaming // Start Streaming
        case .idle:
            initiateNewStream(id: audioIDS[currentAudioIndex], serverUrl: AudioNetwork.audioStreamURL)
        case .error:
            streamState = .idle
            tooglePlay()
        }
        return
    }
    
    func next() {}
    
    func previous() {}
    
    func currentAudioArtists() {
        guard let artists = AudioStream.shared.currentSong?.document.artists else {
            audioArtists = NSLocalizedString("Artists", comment: "")
            return
        }
        if artists.count > 0 {
            for artist in artists {
                audioArtists = ""
                (artists.firstIndex(of: artist) ?? 0) == (artists.count - 1) ? audioArtists.append("\(artist)") : audioArtists.append("\(artist), ")
            }
        } else {
            audioArtists = NSLocalizedString("Artists", comment: "")
        }
        return
    }
}

extension AudioStreamView {
    func initiateNewStream(id: String, serverUrl: String) {
        AudioStream.shared.initiateRequest(id: id, serverUrl: serverUrl, completionHandler: {data, error in
            if let data = data {
                let response = AudioNetwork.decodeJSONDataToResponse(data: data)
                DispatchQueue.main.async {
                    if let responseData = response.0 {
                        AudioStream.shared.currentSong = responseData
                        streamState = .streaming // Start Streaming
                        audioTitle = responseData.document.title
                        print("Audio Stream => \(responseData)")
                        currentAudioArtists()
                    } else if let responseError = response.1 {
                        streamState = .error // Stop Streaming
                        audioTitle = responseError
                        print("Audio Stream (Response Error) => \(audioTitle)")
                        currentAudioArtists()
                    } else {
                        streamState = .error // Stop Streaming
                        audioTitle = NSLocalizedString("Unknown error occured from audio stream request", comment: "")
                        print("Audio Stream => \(audioTitle)")
                        currentAudioArtists()
                    }
                }
            } else if let error = error {
                DispatchQueue.main.async {
                    streamState = .error // Stop Streaming
                    audioTitle = error.localizedDescription
                    print("Audio Stream (Error) => \(audioTitle)")
                    currentAudioArtists()
                }
            } else {
                DispatchQueue.main.async {
                    streamState = .error // Stop Streaming
                    audioTitle = NSLocalizedString("Unknown error occured from audio stream request", comment: "")
                    print("Audio Stream => \(audioTitle)")
                    currentAudioArtists()
                }
            }
        })
    }
}

let contentView = AudioStreamView()
PlaygroundPage.current.liveView = UIHostingController(rootView: contentView)
