import Foundation

final class UserDefaultsStorage: StorageService {
    private let userDefaults: UserDefaults
    
    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }
    
    func save<T: Codable>(_ object: T, forKey key: String) throws {
        do {
            let data = try JSONEncoder().encode(object)
            userDefaults.set(data, forKey: key)
        } catch {
            throw StorageError.encodingFailed
        }
    }
    
    func load<T: Codable>(_ type: T.Type, forKey key: String) throws -> T? {
        guard let data = userDefaults.data(forKey: key) else {
            return nil
        }
        
        do {
            return try JSONDecoder().decode(type, from: data)
        } catch {
            throw StorageError.decodingFailed
        }
    }
    
    func delete(forKey key: String) throws {
        userDefaults.removeObject(forKey: key)
    }
    
    func exists(forKey key: String) -> Bool {
        return userDefaults.object(forKey: key) != nil
    }
}