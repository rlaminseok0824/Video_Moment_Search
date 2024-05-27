package main

import (
	"encoding/json"
	"fmt"
	"math"
)

type Output struct {
	Name     string    `json:"name"`
	Datatype string    `json:"datatype"`
	Shape    []int     `json:"shape"`
	Data     []float32 `json:"data"`
}

type Response struct {
	ModelName    string   `json:"model_name"`
	ModelVersion string   `json:"model_version"`
	Outputs      []Output `json:"outputs"`
}

func reshapeToFloat(data []float32, rows int, cols int) [][]float32 {
	if len(data) != rows*cols {
		return nil // 데이터 길이가 일치하지 않으면 nil을 반환합니다.
	}

	result := make([][]float32, rows)
	for i := 0; i < rows; i++ {
		result[i] = make([]float32, cols)
		for j := 0; j < cols; j++ {
			result[i][j] = data[i*cols+j]
		}
	}

	return result
}

func reshapeToInt(data []float32, rows int, cols int) [][]int32 {
	if len(data) != rows*cols {
		return nil // 데이터 길이가 일치하지 않으면 nil을 반환합니다.
	}

	result := make([][]int32, rows)
	for i := 0; i < rows; i++ {
		result[i] = make([]int32, cols)
		for j := 0; j < cols; j++ {
			if j % 2 ==0 {
				result[i][j] = int32(data[i*cols+j])
 			} else {
				result[i][j] = int32(math.Round(float64(data[i*cols+j])))
			}
			
		}
	}

	return result
}

func DecodeRawData(responseBody string) ([][]float32, [][]int32, error) {
	response := new(Response)
	err := json.Unmarshal([]byte(responseBody),&response)
	if err != nil {
		return nil,nil,err
	}

	var logitsData, spansData []float32
	for _, output := range response.Outputs {
		if output.Name == "LOGITS" {
			logitsData = output.Data
		} else if output.Name == "SPANS" {
			spansData = output.Data
		}
	}

	if logitsData == nil || spansData == nil {
		return nil, nil, fmt.Errorf("missing LOGITS or SPANS data")
	}

	logits := reshapeToFloat(logitsData, 30, 2)
	spans := reshapeToInt(spansData, 30, 2)

	return logits, spans, nil
}

func CreateTritonBody(url string, text string) []byte {
	data := fmt.Sprintf(`{
			"name": "string_identity",
					"inputs": [
						{
							"name": "INPUT0",
							"shape": [1],
							"datatype": "BYTES",
							"data": ["%s"]
						},
						{
							"name": "INPUT1",
							"shape": [1],
							"datatype": "BYTES",
							"data": ["%s"]
						}
					]
    }`,url,text)

	tritonData := []byte(data)

	return tritonData
}

func Combine(logits [][]float32, spans [][]int32, threshold float32) [][]float32{
	var combined [][]float32

	for i := 0; i < len(logits); i++ {
		// logits의 첫번째 값의 확률이 threshold보다 크면 combined에 추가
		if logits[i][0] > threshold {
			combinedRow := []float32{
				float32(spans[i][0]),
				float32(spans[i][1]),
				roundToOneDecimalPlace(logits[i][0]),
			}
			if combinedRow[0] != combinedRow[1] {
				combined = append(combined, combinedRow)	
			}
		}
	}

	return combined
}

func roundToOneDecimalPlace(value float32) float32 {
	rounded := float32(math.Round(float64(value) * 10) / 10)
	if rounded == 1.0 {
		rounded = 0.9
	}
	return rounded
}

func ToString(combined [][]float32) string {
	result := ""
	for _, row := range combined {
		result += fmt.Sprintf(`["%0.1f", "%0.1f", "%0.1f"] `, row[0], row[1], row[2])
	}

	return result
}