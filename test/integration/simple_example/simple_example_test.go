// Copyright 2023 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

package multiple_buckets

import (
	"testing"
	"time"

	"github.com/GoogleCloudPlatform/cloud-foundation-toolkit/infra/blueprint-test/pkg/tft"
	"github.com/stretchr/testify/assert"
)

// Retry if these errors are encountered.
var retryErrors = map[string]string{
	".*does not have enough resources available to fulfill the request.  Try a different zone,.*": "Compute zone resources currently unavailable.",
	".*Error 400: The subnetwork resource*":                                                       "Subnet is eventually drained",
	".*Error waiting for Delete Service Networking Connection: Error code 9*":                     "Service connections are eventually dropped",
	".*Error: Error waiting for Deleting Network: The subnetwork resource*":                       "Subnet is eventually drained, Serverless can take up to 2 hours to release",
}

func TestSimpleExample(t *testing.T) {
	dwh := tft.NewTFBlueprintTest(t, tft.WithRetryableTerraformErrors(retryErrors, 120, time.Minute))

	dwh.DefineVerify(func(assert *assert.Assertions) {
		dwh.DefaultVerify(assert)

		// projectID := dwh.GetTFSetupStringOutput("project_id")
		// TODO add tests

	})

	dwh.DefineTeardown(func(assert *assert.Assertions) {
		dwh.DefaultTeardown(assert)

	})
	dwh.Test()
}
