import SwiftUI
import PlaygroundSupport
import AVFoundation
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

protocol AudioNetwork {
    static func makeNetworkRequest(id: String, url: String, completionHandler: @escaping (Any?, Error?) -> Void)
    static func decodeJSONDataToResponse(data: Data) -> (Decodable?, Error?)
    static func encodeRequestToJSONData(request: Encodable) -> (Data?, Error?)
    static func createURLRequest(id: String, url: String) -> (URLRequest?, Error?)
}

struct AudioStreamNetwork: AudioNetwork {
    
    enum Method: String {
        case get = "GET"
        case post = "POST"
    }
    
    static let audioStreamBaseURL = "http://localhost:8080/"
    
    static func makeNetworkRequest(id: String, url: String, completionHandler: @escaping (Any?, Error?) -> Void) {
        let request = createURLRequest(id: id, url: url)
        guard let urlRequest = request.0 else {
            return completionHandler(nil, request.1)
        }
        let downloadTask = URLSession.shared.dataTask(with: urlRequest, completionHandler: {(data, response, error) in
            guard let data = data else {
                completionHandler(nil, error)
                return
            }
            let response = decodeJSONDataToResponse(data: data)
            guard let audioResponse = response.0 else {
                completionHandler(nil, response.1)
                return
            }
            completionHandler(audioResponse, nil)
        })
        downloadTask.resume()
    }
    
    static func decodeJSONDataToResponse(data: Data) -> (Decodable?, Error?) {
        do {
            return (try JSONDecoder().decode(AudioStreamResponse.self, from: data), nil)
        } catch {
            return (nil, error)
        }
    }
    
    static func encodeRequestToJSONData(request: Encodable) -> (Data?, Error?) {
        do {
            return (try JSONEncoder().encode(request as! AudioStreamRequest), nil)
        } catch {
            return (nil, error)
        }
    }
    
    static func createURLRequest(id: String, url: String) -> (URLRequest?, Error?) {
        let requestBody = AudioStreamRequest(documentID: id)
        let encodedRequestBody = encodeRequestToJSONData(request: requestBody)
        guard let url = URL(string: url), let data = encodedRequestBody.0 else {
            return (nil, encodedRequestBody.1)
        }
        var request = URLRequest(url: url)
        request.httpMethod = Method.post.rawValue
        request.httpBody = data
        return (request, nil)
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
    
    @Published var state: StreamState = .idle
    var playerTitle: String = ""
    
    private var player: AVAudioPlayer?
    private var currentSong: AudioStreamResponse?
    
    func getArtists() -> [String] {
        return currentSong?.document.artists ?? []
    }
    
    func loadAudio(id: String, url: String, completionHandler: @escaping (Error?) -> Void) {
        AudioStreamNetwork.makeNetworkRequest(id: id, url: url, completionHandler: {[weak self] audioResponse, error in
            guard let audioResponse = audioResponse, let song = audioResponse as? AudioStreamResponse else {
                completionHandler(error)
                self?.stop()
                return
            }
            print("Audio Stream => \(song)")
            self?.currentSong = song
            self?.playerTitle = song.document.title
            self?.play()
            completionHandler(nil)
        })
        return
    }
    
    func play() -> Bool {
        if let player = player {
            state = .streaming
            return player.play()
        }
        guard let song = currentSong else {
            print(NSLocalizedString("No song data present", comment: ""))
            state = .error
            return false
        }
        do {
            try player = AVAudioPlayer(data: song.audioBuffer, fileTypeHint: song.document.fileType.rawValue)
            if let player = player {
                state = .streaming
                return player.play()
            }
        } catch {
            print(error.localizedDescription)
        }
        state = .error
        return false
    }
    
    func pause() {
        player?.pause()
        state = .notStreaming
    }
    
    func stop() {
        player?.stop()
        player = nil
        state = .error
    }
}

struct AudioStreamView: View {
    @State private var audioTitle: String = NSLocalizedString("No Audio Streaming", comment: "")
    @State private var audioArtists: String = NSLocalizedString("Artists", comment: "")
    @State private var currentAudioIndex: Int = 0
    private let audioIDS: [String] = ["00", "01", "02", "03"]
    
    var body: some View {
        VStack(alignment: .center) {
            HStack(alignment: .center, spacing: 20) {
                Button(action: tooglePlay) {
                    HStack {
                        AudioStream.shared.state == .streaming ? Image(systemName: "pause.fill"): Image(systemName: "play.fill")
                    }
                }
                Button(action: next) {
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
        switch AudioStream.shared.state {
        case .streaming:
            AudioStream.shared.state = .notStreaming
            AudioStream.shared.pause()
        case .notStreaming:
            AudioStream.shared.state = .streaming
            AudioStream.shared.play()
        case .idle:
            newStream(id: audioIDS[currentAudioIndex], url: AudioStreamNetwork.audioStreamBaseURL)
        case .error:
            AudioStream.shared.state = .idle
            tooglePlay()
        }
        return
    }
    
    func next() {
        AudioStream.shared.stop()
        if currentAudioIndex == audioIDS.count - 1 {
            currentAudioIndex = 0
        } else {
            currentAudioIndex = currentAudioIndex + 1
        }
        newStream(id: audioIDS[currentAudioIndex], url: AudioStreamNetwork.audioStreamBaseURL)
    }
    
    func currentAudioArtists() {
        if AudioStream.shared.getArtists().count > 0 {
            let artists = AudioStream.shared.getArtists()
            audioArtists = ""
            for artist in artists {
                (artists.firstIndex(of: artist) ?? 0) == (artists.count - 1) ? audioArtists.append("\(artist)") : audioArtists.append("\(artist), ")
            }
        } else {
            audioArtists = NSLocalizedString("Artists", comment: "")
        }
        return
    }
}

extension AudioStreamView {
    func newStream(id: String, url: String) {
        AudioStream.shared.loadAudio(id: id, url: url, completionHandler: {error in
            DispatchQueue.main.async {
                if let error = error {
                    audioTitle = error.localizedDescription
                    print("Audio Stream (Error) => \(audioTitle)")
                    currentAudioArtists()
                } else {
                    currentAudioArtists()
                    audioTitle = AudioStream.shared.playerTitle
                }
            }
        })
    }
}

let contentView = AudioStreamView()
PlaygroundPage.current.liveView = UIHostingController(rootView: contentView)
