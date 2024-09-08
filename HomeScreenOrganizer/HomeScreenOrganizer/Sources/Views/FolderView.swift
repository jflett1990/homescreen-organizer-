import UIKit

class FolderView: UIView {
    private let folderNameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 24)
        label.textAlignment = .center
        return label
    }()
    
    private let appCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.itemSize = CGSize(width: 80, height: 100)
        layout.sectionInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .systemBackground
        return collectionView
    }()
    
    private var folder: Folder
    
    init(folder: Folder) {
        self.folder = folder
        super.init(frame: .zero)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = .systemBackground
        
        addSubview(folderNameLabel)
        addSubview(appCollectionView)
        
        folderNameLabel.translatesAutoresizingMaskIntoConstraints = false
        appCollectionView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            folderNameLabel.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 20),
            folderNameLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            folderNameLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            
            appCollectionView.topAnchor.constraint(equalTo: folderNameLabel.bottomAnchor, constant: 20),
            appCollectionView.leadingAnchor.constraint(equalTo: leadingAnchor),
            appCollectionView.trailingAnchor.constraint(equalTo: trailingAnchor),
            appCollectionView.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor)
        ])
        
        appCollectionView.delegate = self
        appCollectionView.dataSource = self
        appCollectionView.register(AppCell.self, forCellWithReuseIdentifier: "AppCell")
        
        updateUI()
    }
    
    private func updateUI() {
        folderNameLabel.text = folder.name
        appCollectionView.reloadData()
    }
    
    func updateFolder(_ folder: Folder) {
        self.folder = folder
        updateUI()
    }
}

extension FolderView: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return folder.apps.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "AppCell", for: indexPath) as? AppCell else {
            fatalError("Unable to dequeue AppCell")
        }
        
        let appBundleIdentifier = folder.apps[indexPath.item]
        cell.configure(with: appBundleIdentifier)
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let appBundleIdentifier = folder.apps[indexPath.item]
        // TODO: Implement app opening logic
        print("Selected app: \(appBundleIdentifier)")
    }
}

class AppCell: UICollectionViewCell {
    private let iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 12)
        label.numberOfLines = 2
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        contentView.addSubview(iconImageView)
        contentView.addSubview(nameLabel)
        
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            iconImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 5),
            iconImageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 60),
            iconImageView.heightAnchor.constraint(equalToConstant: 60),
            
            nameLabel.topAnchor.constraint(equalTo: iconImageView.bottomAnchor, constant: 5),
            nameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 2),
            nameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -2),
            nameLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -2)
        ])
    }
    
    func configure(with bundleIdentifier: String) {
        // TODO: Implement app icon and name fetching logic
        iconImageView.image = UIImage(systemName: "app")
        nameLabel.text = bundleIdentifier
    }
}