#include <iostream>
#include <fstream>
#include <string>
#include <vector>

#include "tools/cpp/runfiles/runfiles.h"
#include "tests/simple_test_runfiles.h"

using ::bazel::tools::cpp::runfiles::Runfiles;

std::vector<std::string> testcases = {
    ::runfile::current::tests::data_foo_a_txt,
    ::runfile::current::tests::data_foo_bar,
    ::runfile::current::tests::data_foo_bar_b_txt,
    ::runfile::current::tests::filegroup_other_module,
    ::runfile::current::tests::filegroup_other_repo,
    ::runfile::current::tests::filegroup_same_module,
    ::runfile::custom_module_name::tests::data_foo_a_txt,
    ::runfile::custom_module_name::tests::data_foo_bar,
    ::runfile::custom_module_name::tests::data_foo_bar_b_txt,
    ::runfile::custom_repo_name::tests::data_foo_a_txt,
    ::runfile::custom_repo_name::tests::data_foo_bar,
    ::runfile::custom_repo_name::tests::data_foo_bar_b_txt,
};

bool assert_valid_runfile(Runfiles* runfiles, const std::string& rlocation_path) {
  std::string path = runfiles->Rlocation(rlocation_path);
  if (path.empty()) {
    std::cerr << "failed to look up runfile: " << rlocation_path << std::endl;
    return false;
  }
  std::ifstream file(path);
  if (!file.good()) {
    std::cerr << "runfile " << rlocation_path << " does not exist at: " << path << std::endl;
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

int main(int argc, char **argv) {
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
