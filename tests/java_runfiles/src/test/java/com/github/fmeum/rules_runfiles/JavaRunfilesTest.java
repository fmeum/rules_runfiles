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

import static com.github.fmeum.rules_runfiles.JavaRunfilesTestRunfiles.current_pkg;
import static runfiles.JavaRunfilesTestCommonRunfiles.current_repo;
import static runfiles.JavaRunfilesTestCommonRunfiles.current_repo.data.foo.bar_b_txt;
import static runfiles.JavaRunfilesTestCommonRunfiles.custom_repo_name;

import com.google.devtools.build.runfiles.Runfiles;
import runfiles.JavaRunfilesTestCommonRunfiles;

import java.io.File;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.util.Map;
import java.util.stream.Stream;

public class JavaRunfilesTest {
  private static final String[] TESTCASES = new String[] {
      JavaRunfilesTestCommonRunfiles.current_repo.data.foo.a_txt,
      // Static imports can be applied at any level, for example to access
      // current_repo directly.
      current_repo.data.foo.bar,
      // Static imports can be applied even to individual files.
      bar_b_txt,
      // Multiple java_runfiles targets can be added to deps as every one has a
      // unique class name.
      JavaRunfilesTestRunfiles.current_pkg.filegroup_other_module,
      current_pkg.filegroup_other_repo,
      current_pkg.filegroup_same_module,
      JavaRunfilesTestCommonRunfiles.custom_module_name.data.foo.a_txt,
      JavaRunfilesTestCommonRunfiles.custom_module_name.data.foo.bar,
      JavaRunfilesTestCommonRunfiles.custom_module_name.data.foo.bar_b_txt,
      custom_repo_name.data.foo.a_txt,
      custom_repo_name.data.foo.bar,
      custom_repo_name.data.foo.bar_b_txt,
      JavaRunfilesTestCommonRunfiles.main_repo.BUILD_bazel,
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