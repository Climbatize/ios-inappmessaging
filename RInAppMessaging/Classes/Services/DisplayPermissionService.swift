internal protocol DisplayPermissionServiceType {
    func checkPermission(forCampaign campaign: CampaignData) -> DisplayPermissionResponse
}

internal struct DisplayPermissionService: DisplayPermissionServiceType, HttpRequestable {

    private let campaignRepository: CampaignRepositoryType
    private let preferenceRepository: IAMPreferenceRepository
    private let configurationRepository: ConfigurationRepositoryType

    private(set) var httpSession: URLSession
    var bundleInfo = BundleInfo.self

    init(campaignRepository: CampaignRepositoryType,
         preferenceRepository: IAMPreferenceRepository,
         configurationRepository: ConfigurationRepositoryType) {

        self.campaignRepository = campaignRepository
        self.preferenceRepository = preferenceRepository
        self.configurationRepository = configurationRepository
        httpSession = URLSession(configuration: configurationRepository.defaultHttpSessionConfiguration)
    }

    func checkPermission(forCampaign campaign: CampaignData) -> DisplayPermissionResponse {
        // In case of error allow campaigns to be displayed anyway
        let requestParams = [
            Constants.Request.campaignID: campaign.campaignId
        ]

        guard let displayPermissionUrl = configurationRepository.getEndpoints()?.displayPermission,
            let responseFromDisplayPermission = try? requestFromServerSync(
                                                        url: displayPermissionUrl,
                                                        httpMethod: .post,
                                                        parameters: requestParams,
                                                        addtionalHeaders: buildRequestHeader()).get().data
        else {
            CommonUtility.debugPrint("InAppMessaging: error getting a response from display permission.")
            return DisplayPermissionResponse(display: true, performPing: false)
        }

        do {
            let decodedResponse = try JSONDecoder().decode(DisplayPermissionResponse.self,
                                                           from: responseFromDisplayPermission)
            return decodedResponse
        } catch {
            CommonUtility.debugPrint("InAppMessaging: error getting a response from display permission.")
        }

        return DisplayPermissionResponse(display: true, performPing: false)
    }
}

// MARK: - HttpRequestable implementation
extension DisplayPermissionService {

    func buildHttpBody(with parameters: [String: Any]?) -> Result<Data, Error> {

        guard let subscriptionId = bundleInfo.inAppSubscriptionId,
            let campaignId = parameters?[Constants.Request.campaignID] as? String,
            let appVersion = bundleInfo.appVersion,
            let sdkVersion = bundleInfo.inAppSdkVersion
            else {
                CommonUtility.debugPrint("InAppMessaging: error while building request body for display permssion.")
                return .failure(RequestError.unknown)
        }

        let permissionRequest = DisplayPermissionRequest(subscriptionId: subscriptionId,
                                                         campaignId: campaignId,
                                                         userIdentifiers: preferenceRepository.getUserIdentifiers(),
                                                         platform: PlatformEnum.ios.rawValue,
                                                         appVersion: appVersion,
                                                         sdkVersion: sdkVersion,
                                                         locale: Locale.current.identifier,
                                                         lastPingInMillis: campaignRepository.lastSyncInMilliseconds ?? 0)
        do {
            let body = try JSONEncoder().encode(permissionRequest)
            return .success(body)
        } catch {
            CommonUtility.debugPrint("InAppMessaging: failed creating a request body.")
            return .failure(error)
        }
    }

    private func buildRequestHeader() -> [Attribute] {
        let Keys = Constants.Request.Header.self
        var additionalHeaders: [Attribute] = []

        if let subId = bundleInfo.inAppSubscriptionId {
            additionalHeaders.append(Attribute(key: Keys.subscriptionID, value: subId))
        }

        return additionalHeaders
    }
}
