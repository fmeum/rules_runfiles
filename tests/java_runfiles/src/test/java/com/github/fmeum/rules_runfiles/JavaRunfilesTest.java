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

package com.github.fmeum.rules_runfiles;

import com.google.devtools.build.runfiles.Runfiles;
import java.io.File;
import java.io.IOException;

public class JavaRunfilesTest {
  private static final String[] TESTCASES = new String[] {
      JavaRunfilesTestRunfiles.CURRENT_DATA_FOO_A_TXT,
      JavaRunfilesTestRunfiles.CURRENT_DATA_FOO_BAR,
      JavaRunfilesTestRunfiles.CURRENT_DATA_FOO_BAR_B_TXT,
      JavaRunfilesTestRunfiles
          .CURRENT_JAVA_RUNFILES_SRC_TEST_JAVA_COM_GITHUB_FMEUM_RULES_RUNFILES_FILEGROUP_OTHER_MODULE,
      JavaRunfilesTestRunfiles
          .CURRENT_JAVA_RUNFILES_SRC_TEST_JAVA_COM_GITHUB_FMEUM_RULES_RUNFILES_FILEGROUP_OTHER_REPO,
      JavaRunfilesTestRunfiles
          .CURRENT_JAVA_RUNFILES_SRC_TEST_JAVA_COM_GITHUB_FMEUM_RULES_RUNFILES_FILEGROUP_SAME_MODULE,
      JavaRunfilesTestRunfiles.CUSTOM_MODULE_NAME_DATA_FOO_A_TXT,
      JavaRunfilesTestRunfiles.CUSTOM_MODULE_NAME_DATA_FOO_BAR,
      JavaRunfilesTestRunfiles.CUSTOM_MODULE_NAME_DATA_FOO_BAR_B_TXT,
      JavaRunfilesTestRunfiles.CUSTOM_REPO_NAME_DATA_FOO_A_TXT,
      JavaRunfilesTestRunfiles.CUSTOM_REPO_NAME_DATA_FOO_BAR,
      JavaRunfilesTestRunfiles.CUSTOM_REPO_NAME_DATA_FOO_BAR_B_TXT,
      JavaRunfilesTestRunfiles.MAIN_BUILD_BAZEL,
  };

  private static boolean assertValidRunfile(Runfiles runfiles, String rlocationPath) {
    String path = runfiles.rlocation(rlocationPath);
    if (path.isEmpty()) {
      System.err.printf("failed to look up runfile: %s%n", rlocationPath);
      return false;
    }
    boolean exists = new File(path).exists();
    if (!exists) {
      System.err.printf("runfile %s does not exist at: %s%n", rlocationPath, path);
      return false;
    }
    return true;
  }

  private static int runTests(Runfiles runfiles) {
    boolean success = true;
    for (String testcase : TESTCASES) {
      if (!assertValidRunfile(runfiles, testcase)) {
        success = false;
      }
    }

    if (success) {
      return 0;
    } else {
      return 1;
    }
  }

  public static void main(String[] args) {
    try {
      Runfiles runfiles = Runfiles.create();
      System.exit(runTests(runfiles));
    } catch (IOException e) {
      e.printStackTrace();
      System.exit(1);
    }
  }
}