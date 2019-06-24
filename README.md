# AsyncImageView
[![Build Status](https://travis-ci.org/NachoSoto/AsyncImageView.svg?branch=master)](https://travis-ci.org/NachoSoto/AsyncImageView)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)

This is a Swift framework that provides an easy to use `UIImageView` subclass for effectively loading and rendering images asynchronously, providing caching, and error handling.

## Example

To try it out you can run the [Example](Example) included in this repo. You'll need to provide your own Flickr API key in `ImageFetcher`.

## Use

Let's assume you have a `struct` with the image you want to render:  

```swift
struct Image: Hashable {
    let url: URL
}
```

To get started, you need to define your own `RendererType`.

```swift
struct ImageViews {
    typealias RendererType = AnyRenderer<Renderer.RenderData, ImageResult, NoError>
    typealias ImageView = AsyncImageView<Renderer.RenderData, Data, RendererType, RendererType>
 
    static func createView() -> ImageView {
        return ImageView(
            initialFrame: .zero,
            renderer: Renderer.singleton.renderer
        )
    }
      
    struct Data: ImageViewDataType {
        let image: Image
        
        init(image: Image) {
            self.image = image
        }
        
        func renderDataWithSize(_ size: CGSize) -> Renderer.RenderData {
            return RenderData(imageData: image, size: size)
        }
    }
    
    final class Renderer {
        let renderer: RendererType
        
        static let singleton: Renderer = {
            return Renderer()
        }()
        
        init() {
            self.renderer = AnyRenderer(
                RemoteImageRenderer<RemoteRenderData>()
                    // AsyncImageView ensures that errors are handled explicitly.
                    // See "fallbacks" below for an alternative to this.
                    .logAndIgnoreErrors  { print("Error downloading image: \($0)") }
                )
        }
                
        // RemoteRenderDataType allows defining a type that represents an image on the Internet.
        public struct RenderData: RemoteRenderDataType {
            public let image: Image
            public let size: CGSize
            
            public var imageURL: URL {
                return self.image.url
            }
        }
    }
}
```

Now, create an instance of `ImageView` inside your view:

```swift
let view = ImageViews.createView()
```

You can assign values of your `Image` type to it. This will asynchronously use the renderer to fetch the image and process it as needed.

```swift
view.data = Image(url: yourUrl)
```

## Features

`RendererType`s are easily composable. Convenience methods are provided for discoverability:

![Autocompletion](/Docs/autocompletion.png?raw=true)

### Memory cache

This provides an easy way to cache processed or downloaded images in memory:

```swift
RemoteImageRenderer<RenderData>()
    .multicasted()
```

### Disk cache

First you need to conform your `RenderDataType` to `DataFileType`:

```swift
public struct RenderData: RenderDataType, DataFileType {
    public let image: Image
    public let size: CGSize
    
    public var uniqueFilename: String {
        return (self.image.url as NSURL)
            .resourceSpecifier!
            .addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!
    }
}

```

Then add the layer of caching to the renderer:

```swift
RemoteImageRenderer<RenderData>()
    .multicasted()
    .withCache(DiskCache.onCacheSubdirectory("images"))
```

`CacheRenderer` provides a high level of customization to allow you to cache images as desired. See the [Example](Example) for a more complex scenario, which provides different layers of caching:

![Disk Cache](/Docs/disk_cache.png?raw=true)

### Placeholders

You can provide a placeholder renderer to your `AsyncImageView`:

```swift
ImageView(
    initialFrame: .zero,
    renderer: Renderer.singleton.normalImageRenderer,
    placeholderRenderer: Renderer.singleton.placeholderImageRenderer
)
```

The image view will use the placeholder whenever its `data` is set to `nil`.

### Error handling

`AsyncImageView` won't accept a renderer that can produce errors (this is checked at compile time). Because of that, you'll need to use `.logAndIgnoreErrors`.

Alternatively, you can use a different renderer (for example, `LocalImageRenderer` to load an image from disk instead) whenever there is an error:

```swift
RemoteImageRenderer<RenderData>()
    .fallback(otherRenderer)
```

### Other features

More documentation will come for other features. In the mean time, feel free to explore the code to find more details:

- `LocalImageRenderer`: load images from the bundle.
- `ImageInflaterRenderer`: rasterize images.
- `ImageProcessingRenderer`: asynchronously apply transformations to images.

## Integration

### Carthage

If you use [Carthage][] to manage your dependencies, simply add
AsyncImageView to your `Cartfile`:

```
github "NachoSoto/AsyncImageView" ~> 5.0
```

If you use Carthage to build your dependencies, make sure you have added `AsyncImageView.framework`, `ReactiveCocoa.framework`, `ReactiveSwift.framework`, and `Result.framework` to the "_Linked Frameworks and Libraries_" section of your target, and have included them in your Carthage framework copying build phase.

## Have a question?

If you need any help, feel free to send me a DM on [Twitter](https://twitter.com/nachosoto), or open a [GitHub issue][].

[Carthage]: https://github.com/Carthage/Carthage/#readme
[GitHub issue]: https://github.com/NachoSoto/AsyncImageView/issues
