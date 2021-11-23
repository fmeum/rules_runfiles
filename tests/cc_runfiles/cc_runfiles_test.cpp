// Copyright 2021 Fabian Meumertzheim
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

#include <fstream>
#include <iostream>
#include <string>
#include <vector>

#include "cc_runfiles/cc_runfiles_test_runfiles.h"
#include "tools/cpp/runfiles/runfiles.h"

using ::bazel::tools::cpp::runfiles::Runfiles;

std::vector<std::string> testcases = {
    ::runfiles::current::data::foo::a_txt,
    ::runfiles::current::data::foo::bar,
    ::runfiles::current::data::foo::bar_b_txt,
    ::runfiles::current::cc_runfiles::filegroup_other_module,
    ::runfiles::current::cc_runfiles::filegroup_other_repo,
    ::runfiles::current::cc_runfiles::filegroup_same_module,
    ::runfiles::custom_module_name::data::foo::a_txt,
    ::runfiles::custom_module_name::data::foo::bar,
    ::runfiles::custom_module_name::data::foo::bar_b_txt,
    ::runfiles::custom_repo_name::data::foo::a_txt,
    ::runfiles::custom_repo_name::data::foo::bar,
    ::runfiles::custom_repo_name::data::foo::bar_b_txt,
    ::runfiles::main::BUILD_bazel,
};

bool assert_valid_runfile(Runfiles* runfiles,
                          const std::string& rlocation_path) {
  std::string path = runfiles->Rlocation(rlocation_path);
  if (path.empty()) {
    std::cerr << "failed to look up runfile: " << rlocation_path << std::endl;
    return false;
  }
  std::ifstream file(path);
  if (!file.good()) {
    std::cerr << "runfile " << rlocation_path << " does not exist at: " << path
              << std::endl;
    return false;
  }
  return true;
}

int run_tests(Runfiles* runfiles) {
  bool success = true;
  for (const std::string& testcase : testcases) {
    if (!assert_valid_runfile(runfiles, testcase)) {
      success = false;
    }
  }

  if (success) {
    return EXIT_SUCCESS;
  } else {
    return EXIT_FAILURE;
  }
}

int main(int argc, char** argv) {
  std::string runfiles_error;
  Runfiles* runfiles = Runfiles::CreateForTest(&runfiles_error);
  if (runfiles == nullptr) {
    runfiles = Runfiles::Create(argv[0], &runfiles_error);
    if (runfiles == nullptr) {
      std::cerr << "Runfiles::CreateForTest and ::Create failed: "
                << runfiles_error << std::endl;
      return EXIT_FAILURE;
    }
  }

  return run_tests(runfiles);
}
