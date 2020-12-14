import SwiftUI
import PlaygroundSupport
PlaygroundPage.current.needsIndefiniteExecution = true

struct AudioStreamRequest: Encodable {
    let documentId: String
}

struct AudioStreamDocument: Decodable {
    let documentId: String
    let artists: [String]
    let title: String
    let fileType: String
    let storageID: String
}

struct Network {
    static let audioStreamURL = "http://127.0.0.1:8080/"
    
    static func makeNetworkRequest(request: URLRequest, completionHandler: @escaping (Data?, Error?) -> Void) {
        let downloadTask = URLSession.shared.dataTask(with: request, completionHandler: {(data, response, error) in
            completionHandler(data, error)
        })
        downloadTask.resume()
    }
    
    static func decodeJSONDataToResponse(data: Data) -> (AudioStreamDocument?, String?) {
        do {
            return (try JSONDecoder().decode(AudioStreamDocument.self, from: data), nil)
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

class Stream: ObservableObject {
    static let shared: Stream = Stream()
    
    enum StreamState {
        case streaming
        case notStreaming
        case idle
        case error
    }
    
    var streamState: StreamState = .idle
    private var streamError: String = ""
    var currentSong: AudioStreamDocument?
    
    func fetchAudioDocument(id: String, completionHandler: @escaping (Data?, Error?) -> Void) {
        streamError = ""
        let requestBody = AudioStreamRequest(documentId: id)
        let encodedRequestBody = Network.encodeRequestToJSONData(request: requestBody)
        
        guard let url = URL(string: Network.audioStreamURL), let data = encodedRequestBody.0 else {
            streamState = .error
            streamError = encodedRequestBody.1 ?? NSLocalizedString("Unable to start audio stream", comment: "")
            print("Audio Stream Internal Error => \(streamError)")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = data
        
        Network.makeNetworkRequest(request: request, completionHandler: completionHandler)
        return
    }
}

struct AudioStreamView: View {
    private let stream: Stream
    @State private var audioTitle: String = "No Audio Streaming"
    @State private var audioArtists: String = "Artists"
    @State private var currentAudioIndex: Int = 0
    private let audioIDS: [String] = ["00", "01", "02", "03"]
    
    init(stream: Stream) {
        self.stream = stream
    }
    
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
                        stream.streamState == .streaming ? Image(systemName: "pause.fill"): Image(systemName: "play.fill")
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
        switch stream.streamState {
        case .streaming:
            stream.streamState = .notStreaming // Stop or Pause Streaming
        case .notStreaming:
            stream.streamState = .streaming // Start Streaming
        case .idle:
            stream.fetchAudioDocument(id: audioIDS[currentAudioIndex], completionHandler: {data, error in
                if let data = data {
                    let response = Network.decodeJSONDataToResponse(data: data)
                    DispatchQueue.main.async {
                        if let responseData = response.0 {
                            stream.currentSong = responseData
                            stream.streamState = .streaming // Start Streaming
                            audioTitle = responseData.title
                            print("Audio Stream => \(audioTitle)")
                            currentAudioArtists()
                        } else if let responseError = response.1 {
                            stream.streamState = .error
                            audioTitle = responseError
                            print("Audio Stream (Response) => \(audioTitle)")
                            currentAudioArtists()
                        } else {
                            stream.streamState = .error
                            audioTitle = NSLocalizedString("Unknown error occured from audio stream request", comment: "")
                            print("Audio Stream => \(audioTitle)")
                            currentAudioArtists()
                        }
                    }
                } else if let error = error {
                    DispatchQueue.main.async {
                        stream.streamState = .error
                        audioTitle = error.localizedDescription
                        print("Audio Stream (Error) => \(audioTitle)")
                        currentAudioArtists()
                    }
                } else {
                    DispatchQueue.main.async {
                        stream.streamState = .error
                        audioTitle = NSLocalizedString("Unknown error occured from audio stream request", comment: "")
                        print("Audio Stream => \(audioTitle)")
                        currentAudioArtists()
                    }
                }
            })
        case .error:
            stream.streamState = .idle // Retry Audio Fetch
            tooglePlay()
        }
        return
    }
    
    func next() {}
    
    func previous() {}
    
    func currentAudioArtists() {
        guard let artists = stream.currentSong?.artists else {
            audioArtists = "Artists"
            return
        }
        if artists.count > 0 {
            for artist in artists {
                audioArtists = ""
                (artists.firstIndex(of: artist) ?? 0) == (artists.count - 1) ? audioArtists.append("\(artist)") : audioArtists.append("\(artist), ")
            }
        } else {
            audioArtists = "Artists"
        }
        return
    }
}

let contentView = AudioStreamView(stream: Stream.shared)
PlaygroundPage.current.liveView = UIHostingController(rootView: contentView)
