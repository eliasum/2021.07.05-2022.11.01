   M S B A M L   `   `   `  ????N  JGridItemsControlLib, Version=1.0.0.0, Culture=neutral, PublicKeyToken=nullV>clr-namespace:GridItemsControlLib;assembly=GridItemsControlLibGridItemsControlLib  5   
    usingGridItemsControl&    usingGridItemsControl.MainWindow   5   	   \ XPresentationFramework, Version=4.0.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35R NWindowsBase, Version=4.0.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35W SPresentationCore, Version=4.0.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35D 9http://schemas.microsoft.com/winfx/2006/xaml/presentation    5   	   R NSystem.Xaml, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089:x,http://schemas.microsoft.com/winfx/2006/xaml     5   	   Mmy>clr-namespace:GridItemsControlLib;assembly=GridItemsControlLib     5   
     ? Title$  
MainWindow??5   	    ? 	Resources 5         provider,  &System.Windows.Data.DataSourceProvider   IsInitialLoadEnabled ? IsAsynchronous ? XPath??%d*  &	        ? 5   
    .  .  $ //Widget??6^   .??5      ?T?T<Configuration xmlns="" key="_036CE061.ControlWorkstation" title="АРМ" description="Автоматизированное рабочее место">
                    <Communication title="Телекоммуникация" description="Технология взаимодействия электронных данных">
                        <Item key="database" title="СУБД" description="Система управления базами данных">
                            <Postgres title="PostgreSQL" description="Свободно распостроняемая объектно-реляционная система управления базами данных">
                                <Item key="localhost:5432:_036CE061.Runtime" login="postgres" password="postgres">
                                    <Equipment key="_036CE061" title="Установка {@key}" description="Установка {@key}">
                                        <Mode title="Pежим" description="Режим проверки изделия на установке">
                                            <Item key="run" title="Запустить" description="Запустить автоматизированный режим" />
                                            <Item key="break" title="Прервать" description="Прервать автоматизированный режим" />
                                        </Mode>
                                        <Scale title="Масштаб" description="Масштаб отображения">
                                            <Slot title="Позиция изделия" description="Позиция для посадочного места изделия">
                                                <Item key="1" title="Поз.№ {@key}" description="Позиция № {@key} посадочного места изделия">
                                                    <Mode title="Pежим" description="Режим проверки изделия на установке">
                                                        <Item key="run" title="Запустить" description="Запустить автоматизированный режим" />
                                                        <Item key="break" title="Прервать" description="Прервать автоматизированный режим" />
                                                    </Mode>
                                                    <Product title="Изделие" description="Проверяемое изделие">
                                                        <SerialNumber title="Серийный №" description="Серийный номер изделия" value="" />
                                                        <Info title="Примечание" description="Дополнительная информация для изделия" value="" />
                                                    </Product>
                                                    <Supply title="Источник питания" description="Источник питания для изделия">
                                                        <Item key="photocathode" title="Фотокатод" description="Фотокатод изделия">
                                                            <Amperage title="Ток" description="Значение тока" symbol="I" unit="[А]" format="F1" value="">
                                                                <Allowance title="Допуск" description="Значение допуска" symbol="Δ" unit="[%]" value="3" />
                                                            </Amperage>
                                                            <Voltage title="Напряжение" description="Значение напряжения" symbol="U" unit="[В]" format="N0" value="">
                                                                <Allowance title="Допуск" description="Значение допуска" symbol="Δ" unit="[%]" value="3" />
                                                            </Voltage>
                                                        </Item>
                                                        <Item key="microchannelplate1" title="МКП1" description="Микроканальная пластина изделия 1">
                                                            <Amperage title="Ток" description="Значение тока" symbol="I" unit="[А]" format="F1" value="">
                                                                <Allowance title="Допуск" description="Значение допуска" symbol="Δ" unit="[%]" value="3" />
                                                            </Amperage>
                                                            <Voltage title="Напряжение" description="Значение напряжения" symbol="U" unit="[В]" format="N0" value="">
                                                                <Allowance title="Допуск" description="Значение допуска" symbol="Δ" unit="[%]" value="3" />
                                                            </Voltage>
                                                        </Item>
                                                        <Item key="microchannelplate12" title="МКП1-2" description="Микроканальная пластина изделия 1-2">
                                                            <Amperage title="Ток" description="Значение тока" symbol="I" unit="[А]" format="F1" value="">
                                                                <Allowance title="Допуск" description="Значение допуска" symbol="Δ" unit="[%]" value="3" />
                                                            </Amperage>
                                                            <Voltage title="Напряжение" description="Значение напряжения" symbol="U" unit="[В]" format="N0" value="">
                                                                <Allowance title="Допуск" description="Значение допуска" symbol="Δ" unit="[%]" value="3" />
                                                            </Voltage>
                                                        </Item>
                                                        <Item key="microchannelplate2" title="МКП2" description="Микроканальная пластина изделия 2">
                                                            <Amperage title="Ток" description="Значение тока" symbol="I" unit="[А]" format="F1" value="">
                                                                <Allowance title="Допуск" description="Значение допуска" symbol="Δ" unit="[%]" value="3" />
                                                            </Amperage>
                                                            <Voltage title="Напряжение" description="Значение напряжения" symbol="U" unit="[В]" format="N0" value="">
                                                                <Allowance title="Допуск" description="Значение допуска" symbol="Δ" unit="[%]" value="3" />
                                                            </Voltage>
                                                        </Item>
                                                        <Item key="anode" title="Анод" description="Анод изделия">
                                                            <Amperage title="Ток" description="Значение тока" symbol="I" unit="[А]" format="F1" value="">
                                                                <Allowance title="Допуск" description="Значение допуска" symbol="Δ" unit="[%]" value="3" />
                                                            </Amperage>
                                                            <Voltage title="Напряжение" description="Значение напряжения" symbol="U" unit="[В]" format="N0" value="">
                                                                <Allowance title="Допуск" description="Значение допуска" symbol="Δ" unit="[%]" value="3" />
                                                            </Voltage>
                                                        </Item>
                                                        <Chart>
                                                            <Widget title="Виджет">
                                                                <Pen title="Перо">
                                                                    <Item key="Item[@key='microchannelplate1']/Amperage/@title">
                                                                        <Color title="Цвет" value="Red" />
                                                                        <Visability title="Видимость" value="Да" />
                                                                        <Thickness title="Толщина" value="1.0" />
                                                                    </Item>
                                                                    <Item key="Item[@key='microchannelplate12']/Voltage/@title">
                                                                        <Color title="Цвет" value="Blue" />
                                                                        <Visability title="Видимость" value="Да" />
                                                                        <Thickness title="Толщина" value="1.0" />
                                                                    </Item>
                                                                </Pen>
                                                            </Widget>
                                                        </Chart>
                                                    </Supply>
                                                </Item>
                                            </Slot>
                                        </Scale>
                                    </Equipment>
                                </Item>
                            </Postgres>
                        </Item>
                    </Communication>
                </Configuration>        5b      5c      .??5d      *   $GridItemsControlLib.GridItemsControl  -   5        $??gridItemsControl1??5e       ? DataContext# [  5d      $??Center=?6B   $??Center=?6_   5e      5f      