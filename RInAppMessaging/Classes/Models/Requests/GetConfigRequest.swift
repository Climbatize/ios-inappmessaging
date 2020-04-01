internal struct GetConfigRequest: Encodable {
    let locale: String
    let appVersion: String
    let platform: Platform
    let appId: String
    let sdkVersion: String
}
