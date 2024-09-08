import UIKit
import CoreLocation

class MainViewController: UIViewController {
    
    private let folderManager = FolderManager.shared
    private let profileManager = ProfileManager.shared
    private let locationManager = CLLocationManager()
    
    private var collectionView: UICollectionView!
    private var profileSegmentedControl: UISegmentedControl!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        setupLocationManager()
        
        NotificationCenter.default.addObserver(self, selector: #selector(updateFolders), name: UIApplication.significantTimeChangeNotification, object: nil)
    }
    
    private func setupUI() {
        setupProfileSegmentedControl()
        setupCollectionView()
    }
    
    private func setupProfileSegmentedControl() {
        let profiles = profileManager.getAllProfiles()
        profileSegmentedControl = UISegmentedControl(items: profiles.map { $0.name })
        profileSegmentedControl.selectedSegmentIndex = 0
        profileSegmentedControl.addTarget(self, action: #selector(profileChanged), for: .valueChanged)
        
        view.addSubview(profileSegmentedControl)
        profileSegmentedControl.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            profileSegmentedControl.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            profileSegmentedControl.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            profileSegmentedControl.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
    }
    
    private func setupCollectionView() {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.itemSize = CGSize(width: view.bounds.width / 3 - 20, height: 100)
        layout.sectionInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .systemBackground
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(FolderCell.self, forCellWithReuseIdentifier: "FolderCell")
        
        view.addSubview(collectionView)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: profileSegmentedControl.bottomAnchor, constant: 20),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    @objc private func updateFolders() {
        guard let location = locationManager.location else { return }
        folderManager.updateSmartFolders(basedOn: location, andTime: Date())
        profileManager.updateCurrentProfile(basedOn: location, andTime: Date())
        updateUIForCurrentProfile()
    }
    
    @objc private func profileChanged() {
        let selectedProfile = profileManager.getAllProfiles()[profileSegmentedControl.selectedSegmentIndex]
        profileManager.setCurrentProfile(selectedProfile)
        updateUIForCurrentProfile()
    }
    
    private func updateUIForCurrentProfile() {
        guard let currentProfile = profileManager.getCurrentProfile() else { return }
        let foldersToShow = folderManager.getAllFolders().filter { currentProfile.folderIds.contains($0.id) }
        // TODO: Update collectionView to show only the folders for the current profile
        collectionView.reloadData()
    }
    
    private func presentFolderView(for folder: Folder) {
        let folderViewController = FolderViewController(folder: folder)
        let navigationController = UINavigationController(rootViewController: folderViewController)
        present(navigationController, animated: true, completion: nil)
    }
}

extension MainViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let currentProfile = profileManager.getCurrentProfile() else { return 0 }
        return folderManager.getAllFolders().filter { currentProfile.folderIds.contains($0.id) }.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FolderCell", for: indexPath) as? FolderCell else {
            fatalError("Unable to dequeue FolderCell")
        }
        
        guard let currentProfile = profileManager.getCurrentProfile() else { return cell }
        let foldersToShow = folderManager.getAllFolders().filter { currentProfile.folderIds.contains($0.id) }
        let folder = foldersToShow[indexPath.item]
        cell.configure(with: folder)
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let currentProfile = profileManager.getCurrentProfile() else { return }
        let foldersToShow = folderManager.getAllFolders().filter { currentProfile.folderIds.contains($0.id) }
        let folder = foldersToShow[indexPath.item]
        presentFolderView(for: folder)
    }
}

extension MainViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        folderManager.updateSmartFolders(basedOn: location, andTime: Date())
        profileManager.updateCurrentProfile(basedOn: location, andTime: Date())
        updateUIForCurrentProfile()
    }
}

class FolderCell: UICollectionViewCell {
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 14)
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
        contentView.backgroundColor = .systemGray6
        contentView.layer.cornerRadius = 10
        contentView.clipsToBounds = true
        
        contentView.addSubview(nameLabel)
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            nameLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            nameLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }
    
    func configure(with folder: Folder) {
        nameLabel.text = folder.name
    }
}

class FolderViewController: UIViewController {
    private let folder: Folder
    private let folderView: FolderView
    
    init(folder: Folder) {
        self.folder = folder
        self.folderView = FolderView(folder: folder)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = folder.name
        view = folderView
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Edit", style: .plain, target: self, action: #selector(editFolder))
    }
    
    @objc private func editFolder() {
        // TODO: Implement folder editing functionality
        print("Edit folder: \(folder.name)")
    }
}