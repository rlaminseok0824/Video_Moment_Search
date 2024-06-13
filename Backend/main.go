package main

import (
	"bytes"
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
	"path/filepath"

	"github.com/gofiber/fiber/v2"
	"github.com/gofiber/fiber/v2/middleware/cors"
	"github.com/google/uuid"
	"github.com/joho/godotenv"
)

type retrievingReq struct {
	videoID string
	text    string
}

func main() {
	log.SetFlags(0)
	err := godotenv.Load()
	if err != nil {
		log.Fatal("Error loading .env file")
	}
	app := fiber.New(fiber.Config{
		// BodyLimit: 1024 * 1024 * 1024, // 1GB
		StreamRequestBody: true,
	})

	app.Use(cors.New(cors.Config{AllowMethods: "GET,POST", AllowOrigins: "*", AllowHeaders: "Origin, Content-Type, Accept"}))

	app.Post("/upload", func(c *fiber.Ctx) error {
		log.Println("upload")

		// 파일을 저장할 디렉토리 경로
		uploadDir := os.Getenv("UPLOAD_DIR")
		if uploadDir == "" {
			uploadDir = "./videos/"
		}
		// 요청에서 파일을 가져옴
		file, err := c.FormFile("file")
		if err != nil {
			log.Fatal(err)
			return err
		}
		uuid := uuid.New().String()
		// 파일의 경로 설정
		filePath := filepath.Join(uploadDir, uuid+filepath.Ext(file.Filename))
		// 파일을 디스크에 저장
		err = c.SaveFile(file, filePath)
		if err != nil {
			return err
		}
		return c.SendString(uuid)
	})

	app.Get("/retrieve", func(c *fiber.Ctx) error {
		fmt.Print("Retrieve\n")
		req := new(retrievingReq)
		// if err := c.QueryParser(req); err != nil {
		// 	return err
		// }
		req.videoID = c.Query("videoID")
		req.text = c.Query("text")
		fmt.Println(req.videoID)
		videoPath := filepath.Join("/model_dir/tmp/", req.videoID+".mp4")

		data := CreateTritonBody(videoPath, req.text)
		rawData, err := fetchTritonServer(data, os.Getenv("TRITON_URL"))
		if err != nil {
			return err
		}
		fmt.Println("")
		fmt.Println("")
		fmt.Println("")

		logit, span, err := DecodeRawData(rawData)
		if err != nil {
			return err
		}

		// log.Println(logit)
		// log.Println()
		// log.Println(span)

		result := CombineAndSort(span, logit)

		fmt.Println(result)

		// result := Combine(logit, span, 0.1)

		// sort.Slice(result, func(i, j int) bool {
		// 	return result[i][2] > result[j][2]
		// })

		strResult := ToString(result[:3])
		return c.SendString(strResult)
	})

	// data := []byte(`{
	//     "name": "string_identity",
	//             "inputs": [
	//                 {
	//                     "name": "INPUT0",
	//                     "shape": [1],
	//                     "datatype": "BYTES",
	//                     "data": ["Test String!"]
	//                 },
	//                 {
	//                     "name": "INPUT1",
	//                     "shape": [1],
	//                     "datatype": "BYTES",
	//                     "data": ["Test String!"]
	//                 }
	//             ]
	// }`)

	// Logits = Score, Spans = Start(버림), End Pair(반올림).
	// 지금 1차원 데이터니까, 그걸 30, 2 shape의 2차원 데이터로 바꾼 후에, 이 뒤에는 Logit 스코어 보고 threshold 0.5 정도 둬서 그 이상의 spans 만 클라이언트 response로 보내주기.
	// 그리고 이걸 클라이언트에서 받아서, 그걸로 video 자르기

	req := new(retrievingReq)
	req.videoID = "36b5afd9-649a-4ce9-ac19-5ba79ed8a6e2"
	req.text = "Chef makes pizza and cuts it up."

	err = test(*req)

	// return

	// 웹 서버 시작
	err = app.Listen("0.0.0.0:8080")
	if err != nil {
		panic(err)
	}
}

func test(req retrievingReq) error {
	fmt.Println(req.videoID)
	videoPath := filepath.Join("/model_dir/tmp/", req.videoID+".mp4")

	data := CreateTritonBody(videoPath, req.text)
	rawData, err := fetchTritonServer(data, os.Getenv("TRITON_URL"))
	if err != nil {
		return err
	}
	fmt.Println("")
	fmt.Println("")
	fmt.Println("")

	logit, span, err := DecodeRawData(rawData)
	if err != nil {
		return err
	}

	// log.Println(logit)
	// log.Println()
	// log.Println(span)

	result := CombineAndSort(span, logit)

	// result := Combine(logit, span, 0.1)

	// sort.Slice(result, func(i, j int) bool {
	// 	return result[i][2] > result[j][2]
	// })

	strResult := ToString(result[:3])

	fmt.Println(strResult)

	return nil
}

func fetchTritonServer(data []byte, url string) (string, error) {
	// return `{"model_name":"preprocess_test","model_version":"1","outputs":[{"name":"LOGITS","datatype":"FP32","shape":[30,2],"data":[0.11767051368951798,0.507016122341156,0.3481569290161133,0.8309321403503418,0.954700231552124,0.09660984575748444,0.914446234703064,0.6442626118659973,0.3458132743835449,0.005489455070346594,0.6988037824630737,0.9286461472511292,0.835748553276062,0.8429458141326904,0.292248398065567,0.8113284111022949,0.3647158741950989,0.06928924471139908,0.6418856978416443,0.7987306714057922,0.7656148076057434,0.6756073236465454,0.7768551707267761,0.3133365511894226,0.6541518568992615,0.15757893025875092,0.9874796271324158,0.7643575072288513,0.619391679763794,0.8859933614730835,0.507469892501831,0.9135292768478394,0.9280556440353394,0.5504249930381775,0.5440147519111633,0.674191415309906,0.19619420170783997,0.7861059904098511,0.055569346994161609,0.4616788327693939,0.7821457386016846,0.3440386950969696,0.7267979979515076,0.948220431804657,0.9287447333335877,0.4540978670120239,0.3852598965167999,0.4512418210506439,0.5651727318763733,0.3660299777984619,0.24934250116348267,0.8331934213638306,0.8745248317718506,0.7067821025848389,0.12736797332763673,0.5576098561286926,0.5201641321182251,0.81123286485672,0.9589901566505432,0.8011747002601624]},{"name":"SPANS","datatype":"FP32","shape":[30,2],"data":[0.11725521087646485,0.8285818099975586,0.09655222296714783,0.657375156879425,0.053858432918787,0.9876999258995056,0.8599356412887573,0.9639151692390442,0.19164900481700898,0.19818560779094697,0.945092499256134,0.2449231743812561,0.4644179940223694,0.3313761353492737,0.45591220259666445,0.8882958292961121,0.5574038028717041,0.05056275427341461,0.7640567421913147,0.4318058490753174,0.3359755873680115,0.9503039717674255,0.5086284875869751,0.16966237127780915,0.1321328580379486,0.04748694971203804,0.5921550989151001,0.7813346982002258,0.390097051858902,0.8442857265472412,0.1622016429901123,0.09836945682764054,0.69732666015625,0.14035174250602723,0.3904113471508026,0.18960554897785188,0.46184664964675906,0.8623045086860657,0.42223286628723147,0.9085693359375,0.17372339963912965,0.8556493520736694,0.3715750277042389,0.5667432546615601,0.32065433263778689,0.47700726985931399,0.6376586556434631,0.5618669390678406,0.38837331533432009,0.3743743300437927,0.3578425645828247,0.38871610164642336,0.9689507484436035,0.8198482394218445,0.41634196043014529,0.0657535120844841,0.6445159912109375,0.18153107166290284,0.04732000082731247,0.3513975441455841]}]}`,nil

	req, err := http.NewRequest("POST", url, bytes.NewBuffer(data))

	// Logits = Score, Spans = Start(버림), End Pair(반올림).
	// 지금 1차원 데이터니까, 그걸 30, 2 shape의 2차원 데이터로 바꾼 후에, 이 뒤에는 Logit 스코어 보고 threshold 0.5 정도 둬서 그 이상의 spans 만 클라이언트 response로 보내주기.
	// 그리고 이걸 클라이언트에서 받아서, 그걸로 video 자르기

	if err != nil {
		log.Fatal(err)
	}

	req.Header.Set("Content-Type", "application/json")

	client := &http.Client{}
	resp, err := client.Do(req)
	if err != nil {
		log.Fatal(err)
	}
	defer resp.Body.Close()

	if resp.StatusCode == 200 {
		body, _ := io.ReadAll(resp.Body)
		log.Println("response Body:", string(body))
		return string(body), nil
	}
	return "", err
}
