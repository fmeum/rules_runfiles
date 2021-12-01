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

import static com.github.fmeum.rules_runfiles.JavaRunfilesTestRunfiles.current_repo;
import static com.github.fmeum.rules_runfiles.JavaRunfilesTestRunfiles.current_repo.data.foo.bar_b_txt;
import static com.github.fmeum.rules_runfiles.JavaRunfilesTestRunfiles.current_repo.java_runfiles.src.test.java.com.github.fmeum.rules_runfiles;
import static com.github.fmeum.rules_runfiles.JavaRunfilesTestRunfiles.custom_repo_name;

import com.google.devtools.build.runfiles.Runfiles;
import java.io.File;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.util.Map;
import java.util.stream.Stream;

public class JavaRunfilesTest {
  private static final String[] TESTCASES = new String[] {
      JavaRunfilesTestRunfiles.current_repo.data.foo.a_txt,
      current_repo.data.foo.bar,
      bar_b_txt,
      rules_runfiles.filegroup_other_module,
      rules_runfiles.filegroup_other_repo,
      rules_runfiles.filegroup_same_module,
      JavaRunfilesTestRunfiles.custom_module_name.data.foo.a_txt,
      JavaRunfilesTestRunfiles.custom_module_name.data.foo.bar,
      JavaRunfilesTestRunfiles.custom_module_name.data.foo.bar_b_txt,
      custom_repo_name.data.foo.a_txt,
      custom_repo_name.data.foo.bar,
      custom_repo_name.data.foo.bar_b_txt,
      JavaRunfilesTestRunfiles.main_repo.BUILD_bazel,
  };

  private static boolean assertValidRunfile(Runfiles runfiles, String rlocationPath) {
    String path = runfiles.rlocation(rlocationPath);
    if (path == null) {
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
      System.err.println();
      System.err.println("runfiles variables:");
      for (Map.Entry<String, String> var : runfiles.getEnvVars().entrySet()) {
        System.err.printf("%s=%s%n", var.getKey(), var.getValue());
      }
      String runfilesManifest = runfiles.getEnvVars().get("RUNFILES_MANIFEST_FILE");
      if (runfilesManifest != null) {
        System.err.println();
        System.err.println("runfiles manifest:");
        try (Stream<String> lines = Files.lines(Paths.get(runfilesManifest))) {
          lines.forEach(System.err::println);
        } catch (IOException e) {
          e.printStackTrace();
        }
      }
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