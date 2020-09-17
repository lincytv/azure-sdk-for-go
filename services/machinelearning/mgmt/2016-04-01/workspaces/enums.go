package workspaces

// Copyright (c) Microsoft and contributors.  All rights reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//
// See the License for the specific language governing permissions and
// limitations under the License.
//
// Code generated by Microsoft (R) AutoRest Code Generator.
// Changes may cause incorrect behavior and will be lost if the code is regenerated.

// State enumerates the values for state.
type State string

const (
	// Deleted ...
	Deleted State = "Deleted"
	// Disabled ...
	Disabled State = "Disabled"
	// Enabled ...
	Enabled State = "Enabled"
	// Migrated ...
	Migrated State = "Migrated"
	// Registered ...
	Registered State = "Registered"
	// Unregistered ...
	Unregistered State = "Unregistered"
	// Updated ...
	Updated State = "Updated"
)

// PossibleStateValues returns an array of possible values for the State const type.
func PossibleStateValues() []State {
	return []State{Deleted, Disabled, Enabled, Migrated, Registered, Unregistered, Updated}
}

// WorkspaceType enumerates the values for workspace type.
type WorkspaceType string

const (
	// Anonymous ...
	Anonymous WorkspaceType = "Anonymous"
	// Free ...
	Free WorkspaceType = "Free"
	// PaidPremium ...
	PaidPremium WorkspaceType = "PaidPremium"
	// PaidStandard ...
	PaidStandard WorkspaceType = "PaidStandard"
	// Production ...
	Production WorkspaceType = "Production"
)

// PossibleWorkspaceTypeValues returns an array of possible values for the WorkspaceType const type.
func PossibleWorkspaceTypeValues() []WorkspaceType {
	return []WorkspaceType{Anonymous, Free, PaidPremium, PaidStandard, Production}
}