# Runnect

# 한줄 소개
러닝과 일상을 Connect하다! 데일리 러닝앱 서비스 Runnect 🏃

### 앱스토어 링크: [Appstore](https://apps.apple.com/kr/app/runnect-%EC%BD%94%EC%8A%A4%EB%A5%BC-%EA%B7%B8%EB%A6%AC%EA%B3%A0-%EA%B3%B5%EC%9C%A0%ED%95%98%EB%8A%94-%EB%8D%B0%EC%9D%BC%EB%A6%AC-%EB%9F%AC%EB%8B%9D%EC%95%B1/id1663884202) v2.2.0

![1](https://github.com/thingineeer/Runnect-iOS/assets/88179341/937f9e65-61e5-4298-b703-bc2cf5022bf6)
![2](https://github.com/thingineeer/Runnect-iOS/assets/88179341/ad913367-65f2-4839-9658-e538bccf2d6c)

<br>

## iOS Developers <~ing>
<img src = "https://github.com/Runnect/Runnect-iOS/assets/88179341/a3633fff-f50b-4afa-a54f-8bd0b3d8668c" width = "40%" height = "40%"> | <img src = "https://github.com/Runnect/Runnect-iOS/assets/88179341/f8884b2b-4cd6-4077-9d9f-683e62f8137f" width = "40%" height = "40%"> |
:---------:|:----------:
[이명진](https://github.com/thingineeer) | [이소진](https://github.com/513sojin) |
😸 | 🐶 |

##  iOS Developers <~ed>
 | <img src = "https://user-images.githubusercontent.com/77267404/210303677-1354bea7-fba4-4824-a22a-27ba56327370.png" width = "40%" height = "40%"> | <img src = "https://user-images.githubusercontent.com/77267404/210303710-db640ea4-a716-4947-812a-9b19aae8d2a4.png" width = "40%" height = "40%"> | <img src = "https://user-images.githubusercontent.com/77267404/210303572-f9581df7-c3c0-46a8-9c63-219384d6dd64.png" width = "40%" height = "40%"> |
 :---------:|:----------:|:---------:
 [이세진](https://github.com/lsj8706) | [이연우](https://github.com/lee-yeonwoo) | [이재현](https://github.com/dlwogus0128) |
   👨🏻‍🌾 | 🥔 | 🍠

![3](https://github.com/thingineeer/Runnect-iOS/assets/88179341/67cf5c2f-83fb-4fea-a192-0c8e47634a58)
![4](https://github.com/thingineeer/Runnect-iOS/assets/88179341/f98af63b-20c7-4605-be54-011ff52392cf)
![5](https://github.com/thingineeer/Runnect-iOS/assets/88179341/9496f6b4-cbcb-4b12-93aa-9a0a0ab941f4)
![6](https://github.com/thingineeer/Runnect-iOS/assets/88179341/c9638911-b9ca-4e99-88ae-dccb4807ea0c)
<br>
<br>

## Development Environment and Using Library
- Development Environment
<p align="left">
<img src ="https://img.shields.io/badge/Swift-5.9-orange?logo=swift">
<img src ="https://img.shields.io/badge/Xcode-16.0-blue?logo=xcode">
<img src ="https://img.shields.io/badge/iOS-17.0-green.svg">

<br>
<br>

- 📚 Library

라이브러리 | 사용 목적 | Version | Management Tool
:---------:|:----------:|:---------: |:---------:
 Moya | 서버 통신 | 15.0.0 | CocoaPods
 SnapKit | UI Layout | 5.6.0 | CocoaPods
 Then | UI 선언 | 3.0.0 | CocoaPods
 Kingfisher | 이미지 처리 | 7.12.0| CocoaPods
 NMapsMap  | 네이버 지도 SDK | 3.17.0| CocoaPods
 Firebase | Dynamic Link(공유), Google Analytics | 11.5.0 | CocoaPods
 DropDown | 드롭 다운 메뉴 | 2.3.13 | CocoaPods
 KakaoSDK | 소셜 로그인 | 2.22.7 | CocoaPods
 
 <br>

 - 🧱 framework

프레임워크 | 사용 이유 
:---------:|:----------:
 UIKit | UI 구현

<br>
<br>

## Coding Convention
<details>
 <summary> ⭐️ Git Branch Convention </summary>
 <div markdown="1">       

 ---
 
 - **Branch Naming Rule**
    - Issue 작성 후 생성되는 번호와 Issue의 간략한 설명 등을 조합하여 Branch 이름 결정
    - `[prefix]/<#IssueNumber>-<Description>`
- **Commit Message Rule**
    - `[Prefix] <#IssueNumber>-<Description>`
- **Code Review Rule**
    - 코드 리뷰를 최대한 달고 반영하자!
 
 <br>

 </div>
 </details>

<details>
 <summary> ⭐️ Git Flow </summary>
 <div markdown="1">       

 ---
 
 ```
1. 작업 단위별 Issue 생성 : 담당자, 라벨, 프로젝트 연결 

2. Fork 받은 로컬 레포에서 develop 브랜치 최신화 : git pull (origin develop) 

3. Branch 생성 : git switch -c Prefix/#IssueNumber-description 
   > 예시) chore/#3-Project-Setting

4. 로컬 환경에서 작업 후 Add -> Commit -> Push -> Pull Request의 과정을 거친다.
   
   Prefix의 의미
   > [Feat] : 새로운 기능 구현
   > [Chore] : 그 이외의 잡일/ 버전 코드 수정, 패키지 구조 변경, 파일 이동, 파일이름 변경
   > [Add] : 코드 변경 없는 단순 파일 추가, 에셋 및 라이브러리 추가
   > [Setting] : 프로젝트 세팅
   > [Fix] : 버그, 오류 해결, 코드 수정
   > [Style] : 코드 포맷팅, 코드 변경이 없는 경우, 주석 수정
   > [Docs] : README나 WIKI 등의 문서 개정
   > [Refactor] : 전면 수정이 있을 때 사용합니다
   > [Test] : 테스트 모드, 리펙토링 테스트 코드 추가

5. Pull Request 작성 
   - closed : #IssueNumber로 이슈 연결, 리뷰어 지정

6. Code Review 완료 후 Pull Request 작성자가 develop Branch로 merge하기
   - Develop Branch protection rules : Merge 전 최소 1 Approve 필요
       - PR 최대 일주일 이내로 코드 리뷰 완료

7. 종료된 Issue와 Pull Request의 Label과 Project를 관리
```

<br>

 </div>
 </details>

<details>
 <summary> ⭐️ Naming & Code Convention </summary>
 <div markdown="1">       

 ---
 
- 함수, 메서드 : **lowerCamelCase** 사용하고, 동사로 시작한다.
- 변수, 상수 : **lowerCamelCase** 사용한다.
- 클래스, 구조체, enum, extension 등 :  **UpperCamelCase** 사용한다.
- 기본 MVC 폴더링 구조에 따라 파일을 구분하여 사용한다.
- 파일, 클래스 명 약어 사용. 단, UI 선언 구문과 메소드에서는 약어를 사용하지 않는다.
    - 예시) ViewController → `VC`
    - 예시) CollectionViewCell → `CVC`
- 뷰 설정을 위한 함수에서는 **set** 키워드를 사용한다.
    - 예시) func configureUI → `func setUI`
    - 예시) func setDelegate ... → `func configureDelegate`
- 이외 기본 명명규칙은 [Swift Style Guide](https://google.github.io/swift/), [API Design Guidelines](https://www.swift.org/documentation/api-design-guidelines/) , [Swift Style Guide](https://github.com/StyleShare/swift-style-guide)를 참고한다.
- 상속받지 않는 클래스는 **final 키워드**를 붙인다.
- 단일 정의 내에서만 사용되는 특정 기능 구현은 **private 접근 제한자**를 적극 사용한다.
- 퀵헬프기능을 활용한 마크업 문법을 활용한 주석을 적극 사용한다.
- 이외는 커스텀한 **SwiftLint Rule**을 적용한다.
   
   
 <br>

 </div>
 </details>

<details>
 <summary> ⭐️ Project Foldering </summary>
 <div markdown="1">       

 ---

```
📦Runnect-iOS
📂 Global
│   📂 Analytics
│   │   ├── GAEvent.swift
│   │   └── GAManager.swift
│   📂 Base
│   │   └── BaseView.swift
│   📂 Extension
│   │   ├── 📂 Combine+
│   │   ├── 📂 Foundation+
│   │   └── 📂 UIKit+
│   📂 Literal
│   📂 Protocols
│   📂 Resource
│   📂 Supports
│   📂 UIComponents
│   └── 📂 Utils
├── 📂 Network
│   ├── 📂 Dto
│   ├── 📂 Foundation
│   ├── 📂 Model
│   ├── 📂 Router
│   └── 📂 Service
├── 📂 Presentation
│   ├── 📂 CourseDetail
│   │   ├── 📂 VC
│   │   └── 📂 Views
│   ├── 📂 CourseDiscovery
│   │   └── 📂 Views
│   ├── 📂 CourseDrawing
│   │   ├── 📂 VC
│   │   └── 📂 Views
│   ├── 📂 CourseStorage
│   │   ├── 📂 VC
│   │   └── 📂 Views
│   ├── 📂 MyPage
│   │   ├── 📂 VC
│   │   └── 📂 Views
│   ├── 📂 Running
│   │   └── 📂 VC
│   ├── 📂 SignIn
│   │   ├── 📂 VC
│   │   └── 📂 Views
│   ├── 📂 Splash
│   │   └── 📂 VC
│   ├── 📂 TabBar
│   │   └── TaBarController.swift
│   └── 📂 UserProfile
│       ├── 📂 CollectionViewCell
│       └── 📂 UserProfileVC.swift
├── 📜 GoogleService-Info.plist
└── 📜 Info.plist
```

 <br>

 </div>
 </details>
