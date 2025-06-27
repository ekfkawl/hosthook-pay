# HostHook Pay
HostHook Pay는 Microsoft에서 제공하는 [Phone Link](https://www.microsoft.com/ko-kr/windows/sync-across-your-devices?r=1)
 호스트 프로세스를 후킹하여 휴대폰 알림을 가로채고, 무통장·계좌이체 입금을 자동으로 확인 가능하도록 도와주는 라이브러리입니다.  
개발자는 입금 SMS 알림을 Redis Pub/Sub을 통해 자신의 서비스에 전달받아 주문 결제 로직만 구현하면 됩니다.

<br>

## ⚙️ 라이브러리 사용 환경 조건
* Windows 10 (1809, Oct 2018 Update) 이상
* 휴대폰과 연결(Phone Link) 버전 1.25052.76.0 이상
* PC와 iPhone 모두 Bluetooth 지원
* iPhone iOS 14.0 이상
* <s>Android 기기는 테스트 안됨❌️</s>

<br>

## 📌 참고 사항
* 실시간 후킹 방식이므로 Phone Link ↔ 휴대폰이 계속 Bluetooth로 연결되어 있어야 합니다.
* 라이브러리를 적용하기 이전 알림은 불러올 수 없습니다.
* 휴대폰에서 해당 앱의 알림이 꺼져 있거나 앱을 열어두면 알림이 발생하지 않아 동작하지 않습니다.

<br>

## 🚀 사용 가이드
>참고: 휴대폰과 연결(Phone Link)에서 설정 → 기능 → 알림을 '**켬**'으로 설정해 두어야 합니다.
1. [알림 필터링 설정](#알림-필터링-설정)
2. [Redis 연결 설정](#redis-연결-설정)
3. [라이브러리 인젝션](#라이브러리-인젝션)
---

## 알림 필터링 설정
> 참고: 설정 파일의 위치를 **C:\hosthookpay.json**로 생성해 주세요.

원하는 알림만 전송되도록 필터링 할 수 있습니다. 띄어쓰기 및 대소문자를 구분합니다.    
연락처에 별칭으로 저장된 번호라면, 번호 대신에 별칭으로 기재해야 합니다.
```
C:\hosthookpay.json:

{
  // 앱 패키지 이름으로 필터링
	"PackageFilter": [
		"com.apple.MobileSMS"
	],
  // 알림 타이틀로 필터링
	"TitleFilter": [
		"+82 10-1234-5678",
		"IBK 기업은행"
	]
}
```

## Redis 연결 설정
휴대폰 알림을 외부 서비스에 전송하기 위해 Redis Pub/Sub이 사용됩니다.    
토픽 이름은 ```HostHookPayTopic``` 입니다.
```
C:\hosthookpay.json:

{
	"Redis": {
	  "Host": "localhost",
	  "Port": 6379,
	  "Password": ""
	},

	"PackageFilter": [
    ..
	],

	"TitleFilter": [
    ..
	]
}
  
```

## 라이브러리 인젝션
`HostHook.dll`과 `injector.exe`를 **같은 폴더**에 넣은 뒤, **Phone Link**가 실행된 상태에서 `injector.exe`를 **관리자 권한**으로 실행하세요.
이후부터 `hosthookpay.json`에 지정한 알림은 외부 서비스로 실시간 전송됩니다!

<br/>

## 🧩 자동 입금 확인 예제
[example](./example/) 디렉터리에는 Java Spring Boot 웹 애플리케이션 예제가 포함되어 있습니다.  
해당 예제는 주문을 생성한 뒤, 입금 SMS를 감지해 자동으로 결제 완료 처리하는 과정을 보여 줍니다.
