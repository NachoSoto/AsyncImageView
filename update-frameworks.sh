#!/bin/bash -e

carthage update AsyncImageView ReactiveSwift --use-xcframeworks --platform ios,tvos,macCatalyst --configuration release --no-skip-current
carthage update Quick Nimble --use-xcframeworks --platform ios --configuration release
