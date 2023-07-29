import utest.Runner;
import utest.ui.Report;

class Main {
  public static function main():Void {
    var runner = new Runner();
    runner.addCases(test);
    // runner.onTestStart.add(test -> trace("running", test.fixture.method));
    Report.create(runner);
    runner.run();
  }
}
