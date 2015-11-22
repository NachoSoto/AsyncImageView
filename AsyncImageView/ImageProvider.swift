//
//  ImageProvider.swift
//  AsyncImageView
//
//  Created by Nacho Soto on 9/17/15.
//  Copyright © 2015 Nacho Soto. All rights reserved.
//

import Foundation
import ReactiveCocoa

public protocol ImageProviderType {
	typealias RenderData: RenderDataType

	func getImageForData(data: RenderData) -> SignalProducer<RenderResult, NoError>
}
