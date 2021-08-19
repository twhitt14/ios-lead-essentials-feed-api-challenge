//
//  Copyright © 2018 Essential Developer. All rights reserved.
//

import Foundation

public final class RemoteFeedLoader: FeedLoader {
	private let url: URL
	private let client: HTTPClient

	public enum Error: Swift.Error {
		case connectivity
		case invalidData
	}

	public init(url: URL, client: HTTPClient) {
		self.url = url
		self.client = client
	}

	public func load(completion: @escaping (FeedLoader.Result) -> Void) {
		client.get(from: url) { [weak self] result in
			guard let self = self else { return }

			switch result {
			case .failure(_):
				completion(.failure(Error.connectivity))
			case .success((let data, let response)):
				guard response.statusCode == 200,
				      let responseObject = try? JSONDecoder().decode(FeedImageResponseObject.self, from: data)
				else {
					completion(.failure(Error.invalidData))
					return
				}

				completion(Result.success(responseObject.itemsAsFeedImageArray()))
			}
		}
	}

	private struct FeedImageResponseObject: Decodable {
		let items: [FeedImageObject]

		func itemsAsFeedImageArray() -> [FeedImage] {
			items.map { $0.asFeedImage() }
		}
	}

	private struct FeedImageObject: Decodable {
		let image_id: UUID
		let image_desc: String?
		let image_loc: String?
		let image_url: URL

		func asFeedImage() -> FeedImage {
			FeedImage(id: image_id,
			          description: image_desc,
			          location: image_loc,
			          url: image_url)
		}
	}
}
