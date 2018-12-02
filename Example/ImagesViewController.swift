//
//  ViewController.swift
//  Example
//
//  Created by Nacho Soto on 11/30/18.
//  Copyright © 2018 Nacho Soto. All rights reserved.
//

import UIKit

import Result
import ReactiveSwift

final class ImagesViewController: UIViewController {
    private let fetcher: ImageFetcher
    
    init(fetcher: ImageFetcher) {
        self.fetcher = fetcher
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var openImageRequests: Signal<FlickrImageData, NoError> {
        return self.collectionView.openImageRequests
    }
    
    // MARK: -
    
    override func loadView() {
        self.view = {
            let view = UIView()
            view.addSubview(self.collectionView)
            
            return view
        }()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.searchBar.delegate = self
        self.navigationItem.titleView = self.searchBar
        
        self.queries
            .producer
            .skipRepeats()
            .filter { !$0.isEmpty }
            .debounce(ImagesViewController.debounceDuration, on: QueueScheduler())
            .flatMap(.latest) { [fetcher = self.fetcher] query in
                fetcher
                    .fetchImages(query: query)
                    .on(starting: { print("Searching: \(query)") })
            }
            .observe(on: UIScheduler())
            .take(during: self.reactive.lifetime)
            .startWithResult { result in
                switch result {
                case .success(let images):
                    self.collectionView.images = images

                case .failure(let error):
                    print("Error: \(error)")
                }
            }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        self.collectionView.frame = self.view.bounds
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.searchBar.becomeFirstResponder()
    }
    
    // MARK: -
    
    private let queries = MutableProperty<String>("")
    
    // MARK: - Views
    
    private lazy var collectionView = CollectionView()
    
    private let searchBar: UISearchBar = {
        let searchBar = UISearchBar()
        searchBar.searchBarStyle = .minimal
        searchBar.placeholder = "Search…"
        searchBar.sizeToFit()
        searchBar.isTranslucent = true
        searchBar.backgroundImage = UIImage()
        
        return searchBar
    }()
    
    // MARK: -
    
    private static let debounceDuration: TimeInterval = 0.3
}

extension ImagesViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        self.queries.value = searchText
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}

private final class CollectionView: UIView {
    private let dataSource = DataSource()
    
    private let collectionView: UICollectionView
    
    private let layout: UICollectionViewFlowLayout = {
        let layout = UICollectionViewFlowLayout()
        
        return layout
    }()
    
    init() {
        self.collectionView = UICollectionView(
            frame: .zero,
            collectionViewLayout: self.layout
        )
        
        (self.openImageRequests, self.openImageRequestsObserver) = Signal.pipe()
        
        super.init(frame: .zero)
        
        self.collectionView.contentInsetAdjustmentBehavior = .always
        self.collectionView.dataSource = self.dataSource
        self.collectionView.delegate = self
        self.collectionView.collectionViewLayout = self.layout
        
        self.collectionView.register(Cell.self, forCellWithReuseIdentifier: Cell.reuseIdentifier)
        
        self.addSubview(self.collectionView)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: -
    
    var images: [FlickrImageData] = [] {
        didSet {
            self.dataSource.images = self.images
            self.collectionView.reloadData()
        }
    }
    
    let openImageRequests: Signal<FlickrImageData, NoError>
    private let openImageRequestsObserver: Signal<FlickrImageData, NoError>.Observer
    
    // MARK: -
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        guard self.bounds.size.width > 0 else { return }
        
        let availableWidth = self.bounds.size.width
            - self.collectionView.adjustedContentInset.left
            - self.collectionView.adjustedContentInset.right
        let imageWidth: CGFloat = (availableWidth / CGFloat(CollectionView.imagesPerRow)) - self.layout.minimumLineSpacing
        
        self.layout.itemSize = CGSize(
            width: imageWidth,
            height: imageWidth
        )
        self.collectionView.frame = self.bounds
    }
    
    private static let imagesPerRow: Int = 3
}

extension CollectionView: UICollectionViewDelegate {
    func collectionView(
        _ collectionView: UICollectionView,
        didSelectItemAt indexPath: IndexPath
    ) {
        self.openImageRequestsObserver.send(value: self.images[indexPath.item])
    }
}

private final class Cell: UICollectionViewCell {
    private let imageView: Photos.ImageView = {
        return Photos.createAspectFillView(initialFrame: .zero)
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.contentView.addSubview(self.imageView)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        self.imageView.frame = self.bounds
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        self.data = nil
    }
    
    // MARK: -
    
    var data: FlickrImageData? {
        get { return self.imageView.data?.imageData }
        set { self.imageView.data = newValue.map(Photos.Data.init) }
    }
    
    static let reuseIdentifier: String = "cell"
}

private final class DataSource: NSObject, UICollectionViewDataSource {
    var images: [FlickrImageData] = []
    
    @objc func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }

    @objc func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.images.count
    }
    
    @objc func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Cell.reuseIdentifier, for: indexPath) as! Cell
        cell.data = self.images[indexPath.item]
        
        return cell
    }
}
